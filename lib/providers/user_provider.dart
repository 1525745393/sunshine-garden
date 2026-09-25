import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database_helper.dart';
import '../models/user_profile.dart';

/// 用户全局状态：档案 / 积分 / 每日时长 / 设置
class UserProvider extends ChangeNotifier {
  UserProvider._();
  static final UserProvider instance = UserProvider._();

  static const _kUserId = 'current_user_id';
  static const _kTodayKey = 'today_key';
  static const _kTodaySeconds = 'today_used_seconds';
  static const _kPrivacyAccepted = 'privacy_accepted';
  static const _kTimeLockNoticeKey = 'time_lock_notice_key';
  static const _kTodayEarnedScore = 'today_earned_score';
  static const _kTodayEnough = 'today_played_enough';
  static const _kStreakRewarded = 'streak_7_rewarded';
  static const _kBadgePersist = 'badge_persist_unlocked';
  static const _kPomodoroNoticeKey = 'pomodoro_notice_key';

  /// 坚持打卡：连续 7 天每天玩满 10 分钟 → +20 分 + 勋章
  static const int streakTargetDays = 7;
  static const int streakDailySeconds = 600; // 10 分钟
  static const int streakBonusScore = 20;

  UserProfile? _profile;
  bool _loaded = false;

  /// 今日已用时长（秒），跨日自动重置
  int _todayUsedSeconds = 0;
  /// 今日累计获得积分（受每日上限约束）
  int _todayEarnedScore = 0;
  /// 今日是否已玩满 10 分钟（打卡达标）
  bool _todayPlayedEnough = false;
  /// 连续 7 天奖励是否已发放
  bool _streak7Rewarded = false;
  /// 待展示的奖励提示（如"坚持之星"解锁）
  String? _rewardMessage;
  String _todayKey = '';
  bool _privacyAccepted = false;
  bool _initFailed = false;

  UserProfile? get profile => _profile;
  bool get isLoaded => _loaded;
  bool get initFailed => _initFailed;
  bool get privacyAccepted => _privacyAccepted;
  int get totalScore => _profile?.totalScore ?? 0;

  /// 今日已用时长（秒）
  int get todayUsedSeconds => _todayUsedSeconds;

  /// 今日累计获得积分
  int get todayEarnedScore => _todayEarnedScore;

  /// 今日是否已玩满 10 分钟（打卡达标）
  bool get todayPlayedEnough => _todayPlayedEnough;

  /// 每日积分上限（0=不限）
  int get dailyScoreLimit => _profile?.dailyScoreLimit ?? 0;

  /// 今日剩余可赚积分（上限内）
  int get todayRemainingScore {
    final limit = dailyScoreLimit;
    if (limit <= 0) return 0;
    return (limit - _todayEarnedScore).clamp(0, limit);
  }

  /// 今日剩余秒数
  int get todayRemainingSeconds {
    final limit = (_profile?.dailyMinutes ?? 20) * 60;
    return (limit - _todayUsedSeconds).clamp(0, limit);
  }

  /// 今日时长是否已用尽（超时锁定新关卡）
  bool get isTimeUp => todayRemainingSeconds <= 0;

  /// 每日时长上限（秒）
  int get dailyLimitSeconds => (_profile?.dailyMinutes ?? 20) * 60;

  // ---------- 番茄钟（v1.4） ----------
  bool get pomodoroEnabled => _profile?.pomodoroEnabled ?? true;
  int get focusMinutes => _profile?.focusMinutes ?? 15;
  int get breakMinutes => _profile?.breakMinutes ?? 3;

  /// 一个完整番茄周期（学习 + 休息）的秒数
  int get pomodoroCycleSeconds => (focusMinutes + breakMinutes) * 60;

  /// 当前处于休息阶段
  bool get isPomodoroBreak {
    if (!pomodoroEnabled) return false;
    final cycle = pomodoroCycleSeconds;
    if (cycle <= 0) return false;
    final phase = _todayUsedSeconds % cycle;
    return phase >= focusMinutes * 60;
  }

  /// 当前阶段剩余秒数（学习 / 休息）
  int get pomodoroRemainingSeconds {
    if (!pomodoroEnabled) return 0;
    final cycle = pomodoroCycleSeconds;
    if (cycle <= 0) return 0;
    final phase = _todayUsedSeconds % cycle;
    final focusSec = focusMinutes * 60;
    if (phase < focusSec) return focusSec - phase;
    return cycle - phase;
  }

  /// 应用启动时加载用户与跨日重置
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _privacyAccepted = prefs.getBool(_kPrivacyAccepted) ?? false;

      // 跨日重置：今日时长 / 今日积分 / 打卡标记
      final now = DateTime.now();
      final todayKey = _dayKey(now);
      final storedDay = prefs.getString(_kTodayKey) ?? '';
      if (storedDay != todayKey) {
        await prefs.setString(_kTodayKey, todayKey);
        await prefs.setInt(_kTodaySeconds, 0);
        await prefs.setInt(_kTodayEarnedScore, 0);
        await prefs.setBool(_kTodayEnough, false);
        _todayUsedSeconds = 0;
        _todayEarnedScore = 0;
        _todayPlayedEnough = false;
      } else {
        _todayUsedSeconds = prefs.getInt(_kTodaySeconds) ?? 0;
        _todayEarnedScore = prefs.getInt(_kTodayEarnedScore) ?? 0;
        _todayPlayedEnough = prefs.getBool(_kTodayEnough) ?? false;
      }
      _todayKey = todayKey;
      _streak7Rewarded = prefs.getBool(_kStreakRewarded) ?? false;

      // 加载用户
      final userId = prefs.getString(_kUserId);
      if (userId != null) {
        _profile = await DatabaseHelper.instance.getUser(userId);
      }
      if (_profile != null) {
        _checkDailyRollover();
      }
      _loaded = true;
      notifyListeners();
    } catch (e) {
      // 数据库未就绪等初始化异常：标记失败，页面展示重试
      debugPrint('UserProvider.load error: $e');
      _initFailed = true;
      _loaded = true;
      notifyListeners();
    }
  }

  /// 跨日判断：更新连续打卡天数
  void _checkDailyRollover() {
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    final last = _profile!.lastActiveDayKey;
    if (last == todayKey) return;
    if (last != null) {
      final lastDate = DateTime.parse(last);
      final diff = now.difference(lastDate).inDays;
      _profile!.continuousDays = diff == 1 ? _profile!.continuousDays + 1 : 1;
    } else {
      _profile!.continuousDays = 1;
    }
    _profile!.lastActiveDayKey = todayKey;
    _profile!.lastActiveDate = now;
    _persistProfile();
  }

  /// 创建档案（首次引导）
  Future<void> createProfile({
    required String nickname,
    required StudyStage stage,
    required String grade,
  }) async {
    final profile = UserProfile(
      id: 'user_001',
      nickname: nickname,
      stage: stage,
      grade: grade,
    );
    _profile = profile;
    _todayKey = _dayKey(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, profile.id);
    await DatabaseHelper.instance.upsertUser(profile);
    notifyListeners();
  }

  /// 家长中心修改设置
  Future<void> updateSettings({
    StudyStage? stage,
    String? grade,
    int? dailyMinutes,
    bool? soundEnabled,
    bool? animationEnabled,
    bool? darkMode,
    int? dailyTargetScore,
    bool? filterCurrentStage,
    int? dailyScoreLimit,
    bool? pomodoroEnabled,
    int? focusMinutes,
    int? breakMinutes,
  }) async {
    final p = _profile;
    if (p == null) return;
    if (stage != null) p.stage = stage;
    if (grade != null) p.grade = grade;
    if (dailyMinutes != null) p.dailyMinutes = dailyMinutes;
    if (soundEnabled != null) p.soundEnabled = soundEnabled;
    if (animationEnabled != null) p.animationEnabled = animationEnabled;
    if (darkMode != null) p.darkMode = darkMode;
    if (dailyTargetScore != null) p.dailyTargetScore = dailyTargetScore;
    if (filterCurrentStage != null) p.filterCurrentStage = filterCurrentStage;
    if (dailyScoreLimit != null) p.dailyScoreLimit = dailyScoreLimit;
    if (pomodoroEnabled != null) p.pomodoroEnabled = pomodoroEnabled;
    if (focusMinutes != null) p.focusMinutes = focusMinutes;
    if (breakMinutes != null) p.breakMinutes = breakMinutes;
    await _persistProfile();
  }

  /// 积分增减（闯关 / 任务 / 兑换扣分），持久化
  /// 正分受每日积分上限约束（0=不限），负分（兑换扣分）不受限
  Future<void> changeScore(int delta) async {
    final p = _profile;
    if (p == null) return;

    var actual = delta;
    if (delta > 0) {
      final limit = p.dailyScoreLimit;
      if (limit > 0) {
        final room = (limit - _todayEarnedScore).clamp(0, limit);
        actual = room > 0 ? delta.clamp(0, room) : 0;
        if (actual > 0) {
          _todayEarnedScore += actual;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_kTodayEarnedScore, _todayEarnedScore);
        }
      } else {
        _todayEarnedScore += actual;
      }
    }

    if (actual == 0) return;
    p.totalScore = (p.totalScore + actual).clamp(0, 999999);
    await _persistProfile();
  }

  Future<void> _persistProfile() async {
    if (_profile == null) return;
    await DatabaseHelper.instance.upsertUser(_profile!);
    notifyListeners();
  }

  /// 家长中心：一键清除本地全部数据
  Future<void> wipeAllData() async {
    await DatabaseHelper.instance.wipeAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kTodayKey);
    await prefs.remove(_kTodaySeconds);
    await prefs.remove(_kTodayEarnedScore);
    await prefs.remove(_kTodayEnough);
    await prefs.remove(_kStreakRewarded);
    await prefs.remove(_kBadgePersist);
    _profile = null;
    _todayUsedSeconds = 0;
    _todayEarnedScore = 0;
    _todayPlayedEnough = false;
    notifyListeners();
  }

  /// 家长确认隐私协议（首次启动）
  Future<void> acceptPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrivacyAccepted, true);
    _privacyAccepted = true;
    notifyListeners();
  }

  /// 累计前台活跃时长（秒）；每次状态切换调用，持久化到 prefs
  /// 同时驱动番茄钟阶段切换与"坚持之星"连续打卡奖励
  Future<void> addActiveSeconds(int seconds) async {
    if (seconds <= 0) return;
    final before = _todayUsedSeconds;
    _todayUsedSeconds += seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTodaySeconds, _todayUsedSeconds);

    // 连续打卡：今日玩满 10 分钟 → 标记；满 7 天且未发奖 → 发放奖励
    // （番茄钟休息提示由 consumePomodoroBreakNotice 单独消费）
    if (!_todayPlayedEnough &&
        _todayUsedSeconds >= streakDailySeconds) {
      _todayPlayedEnough = true;
      await prefs.setBool(_kTodayEnough, true);
      if (!_streak7Rewarded) {
        final days = _profile?.continuousDays ?? 0;
        if (days >= streakTargetDays) {
          _streak7Rewarded = true;
          await prefs.setBool(_kStreakRewarded, true);
          await prefs.setBool(_kBadgePersist, true);
          _rewardMessage ??=
              '🌟 连续 $days 天打卡！+$streakBonusScore 分，解锁「坚持之星」';
          await changeScore(streakBonusScore);
        }
      }
    }
    if (before != _todayUsedSeconds) notifyListeners();
  }

  /// 取走待展示的奖励提示（一次性消费）
  String? consumeRewardMessage() {
    final msg = _rewardMessage;
    _rewardMessage = null;
    return msg;
  }

  /// 判断是否需要弹"今日时间到"提示（每天只弹一次）
  Future<bool> consumeTimeUpNotice() async {
    if (!isTimeUp) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kTimeLockNoticeKey$_todayKey';
    final shown = prefs.getBool(key) ?? false;
    if (shown) return false;
    await prefs.setBool(key, true);
    return true;
  }

  /// 判断是否弹出番茄钟休息提示（每次休息阶段开始只弹一次）
  Future<bool> consumePomodoroBreakNotice() async {
    if (!pomodoroEnabled || !isPomodoroBreak) return false;
    final prefs = await SharedPreferences.getInstance();
    final cycleIndex = _todayUsedSeconds ~/ pomodoroCycleSeconds;
    final key = '$_kPomodoroNoticeKey$_todayKey$cycleIndex';
    final shown = prefs.getBool(key) ?? false;
    if (shown) return false;
    await prefs.setBool(key, true);
    return true;
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
