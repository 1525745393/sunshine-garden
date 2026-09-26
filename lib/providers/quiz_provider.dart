import 'dart:math';

import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../mock/badges.dart';
import '../mock/question_bank.dart';
import '../models/level.dart';
import '../models/mistake.dart';
import '../models/question.dart';
import '../models/reward.dart';
import '../models/study_record.dart';
import '../models/user_profile.dart';
import 'user_provider.dart';

/// 单题作答记录
class AnswerRecord {
  final Question question;
  final String userAnswer;
  final bool correct;

  AnswerRecord({
    required this.question,
    required this.userAnswer,
    required this.correct,
  });
}

/// 闯关会话（一关一次）
class QuizSession {
  final Level level;
  final List<Question> questions; // 题目乱序
  int currentIndex = 0;
  int correctCount = 0;
  int streak = 0; // 当前连对计数
  final List<AnswerRecord> answers = [];

  QuizSession({required this.level, required this.questions});
}

/// 闯关全局状态：关卡进度 / 闯关会话 / 错题本 / 积分结算
class QuizProvider extends ChangeNotifier {
  QuizProvider._();
  static final QuizProvider instance = QuizProvider._();

  final Random _random = Random();

  List<Level> _levels = [];
  bool _levelsLoaded = false;
  QuizSession? _session;
  List<Mistake> _mistakes = [];
  bool _mistakesLoaded = false;
  List<Badge> _badges = [];
  bool _badgesLoaded = false;

  List<Level> get levels => _levels;
  QuizSession? get session => _session;
  List<Mistake> get mistakes => _mistakes;
  List<Badge> get badges => _badges;
  int get unlockedBadgeCount => _badges.where((b) => b.unlocked).length;

  /// 今日是否可挑战新关卡（超时锁定；复习错题不受限）
  bool get canChallengeNew => !UserProvider.instance.isTimeUp;

  /// 加载当前学段关卡（mock 数据 + 数据库进度合并）
  Future<void> loadLevels() async {
    final stage = UserProvider.instance.profile?.stage.name ?? 'primary';
    final defs = levelsForStage(stage);
    final saved = await DatabaseHelper.instance.getLevels(UserProvider.instance.currentProfileId);
    _levels = defs.map((level) {
      final s = saved[level.id];
      if (s != null) {
        level.starCount = s.starCount;
        level.unlocked = s.unlocked;
      }
      return level;
    }).toList();
    // 首关默认解锁
    if (_levels.isNotEmpty && !_levels.first.unlocked) {
      _levels.first.unlocked = true;
      await DatabaseHelper.instance.upsertLevel(UserProvider.instance.currentProfileId, _levels.first);
    }
    _levelsLoaded = true;
    notifyListeners();
  }

  /// 开始一关：题目乱序
  void startLevel(Level level) {
    final questions = List<Question>.of(level.questions)..shuffle(_random);
    _session = QuizSession(level: level, questions: questions);
    notifyListeners();
  }

  /// 当前题目
  Question get currentQuestion => _session!.questions[_session!.currentIndex];

  /// 提交答案：即时反馈 + 积分/连对/错题处理
  ///
  /// 返回本项得分（用于 SnackBar 展示）
  Future<int> submitAnswer(String userAnswer) async {
    final s = _session!;
    final q = currentQuestion;
    final correct = _normalize(q.answer) == _normalize(userAnswer);
    var gained = 0;

    s.answers.add(AnswerRecord(
      question: q,
      userAnswer: userAnswer,
      correct: correct,
    ));

    if (correct) {
      s.correctCount++;
      s.streak++;
      gained += 2; // 基础得分

      // 连对 3 题额外 +2（每达 3 连对触发一次）
      if (s.streak >= 3) {
        gained += 2;
        s.streak = 0;
      }
    } else {
      s.streak = 0;
      // 答错自动入错题本（遗忘曲线节点：+1 天，v1.1 演进 +3/+7）
      final mistake = Mistake(
        id: q.id,
        questionText: q.question,
        userAnswer: userAnswer,
        correctAnswer: q.answer,
        analysis: q.analysis,
        addedAt: DateTime.now(),
        nextReviewAt: DateTime.now().add(const Duration(days: 1)),
      );
      await DatabaseHelper.instance.upsertMistake(UserProvider.instance.currentProfileId, mistake);
    }

    if (gained > 0) {
      await UserProvider.instance.changeScore(gained);
    }
    notifyListeners();
    return gained;
  }

  /// 下一题；返回是否还有下一题
  bool nextQuestion() {
    final s = _session!;
    if (s.currentIndex >= s.questions.length - 1) return false;
    s.currentIndex++;
    notifyListeners();
    return true;
  }

  /// 结算：星级 + 满星奖励 + 努力值 + 解锁下一关 + 学习记录
  /// 返回结算信息（页面展示）
  Future<QuizResult> finishLevel() async {
    final s = _session!;
    final level = s.level;
    final total = s.questions.length;
    final correct = s.correctCount;

    final stars = _starsFor(total, correct);
    var gained = 0;

    // 满星通关额外 +5
    if (stars == 3) gained += 5;
    // 努力值：认真完成一关，即使答错也给鼓励分
    gained += 2;

    if (gained > 0) {
      await UserProvider.instance.changeScore(gained);
    }

    // 保存关卡进度（取历史最高星级）
    final prevStars = level.starCount;
    final finalStars = max(prevStars, stars);
    level.starCount = finalStars;

    // 解锁下一关
    final idx = _levels.indexWhere((l) => l.id == level.id);
    if (idx >= 0 && idx < _levels.length - 1) {
      _levels[idx + 1].unlocked = true;
      await DatabaseHelper.instance.upsertLevel(UserProvider.instance.currentProfileId, _levels[idx + 1]);
    }
    await DatabaseHelper.instance.upsertLevel(UserProvider.instance.currentProfileId, level);

    // 学习记录
    await DatabaseHelper.instance.insertRecord(UserProvider.instance.currentProfileId, StudyRecord(
      id: 'rec_${DateTime.now().microsecondsSinceEpoch}',
      dayKey: _dayKey(),
      createdAt: DateTime.now(),
      type: 'quiz',
      title: '闯关 · ${level.name}',
      detail: '${level.subject}·${level.unit}｜答对 $correct/$total｜获得 $stars 星',
      scoreChange: gained,
    ));

    _session = null;
    notifyListeners();
    await refreshBadges();

    return QuizResult(
      level: level,
      correct: correct,
      total: total,
      stars: stars,
      bonusScore: gained,
    );
  }

  /// 星级规则：全对 3 星；答对 >= 总题数-1 得 2 星；
  /// 答对 >= 一半 得 1 星；否则未通关 0 星（需重玩）
  int _starsFor(int total, int correct) {
    if (correct >= total) return 3;
    if (correct >= total - 1) return 2;
    if (correct * 2 >= total) return 1;
    return 0;
  }

  /// 答案归一化（去空白、统一小写，兼容填空）
  String _normalize(String s) => s.trim().toLowerCase();

  // ---------- 错题本 ----------
  Future<void> loadMistakes() async {
    _mistakes = await DatabaseHelper.instance.getMistakes(UserProvider.instance.currentProfileId, resolved: false);
    _mistakesLoaded = true;
    notifyListeners();
  }

  /// 从题库反查题目（错题重做用，v1.4 遍历全部学段）
  Question? findQuestion(String id) {
    for (final stage in StudyStage.values) {
      for (final level in levelsForStage(stage.name)) {
        for (final q in level.questions) {
          if (q.id == id) return q;
        }
      }
    }
    return null;
  }

  /// 错题重做错误：按遗忘曲线顺延复习节点（+1 天），留在错题本
  Future<void> postponeMistake(Mistake mistake) async {
    mistake.nextReviewAt =
        DateTime.now().add(const Duration(days: 1));
    await DatabaseHelper.instance.upsertMistake(UserProvider.instance.currentProfileId, mistake);
    notifyListeners();
  }

  /// 错题重做正确：+2 积分、移出错题本、写学习记录
  Future<void> resolveMistake(Mistake mistake) async {
    await DatabaseHelper.instance.deleteMistake(UserProvider.instance.currentProfileId, mistake.id);
    _mistakes.removeWhere((m) => m.id == mistake.id);
    await UserProvider.instance.changeScore(2);
    await DatabaseHelper.instance.insertRecord(UserProvider.instance.currentProfileId, StudyRecord(
      id: 'rec_${DateTime.now().microsecondsSinceEpoch}',
      dayKey: _dayKey(),
      createdAt: DateTime.now(),
      type: 'task',
      title: '错题重做',
      detail: '重做正确：${mistake.questionText}',
      scoreChange: 2,
    ));
    notifyListeners();
  }

  // ---------- 勋章 ----------
  /// 初始化默认勋章到本地库并读取解锁状态
  Future<void> loadBadges() async {
    for (final b in defaultBadges) {
      await DatabaseHelper.instance.upsertBadge(
        userId: UserProvider.instance.currentProfileId,
        id: b.id,
        name: b.name,
        icon: b.icon,
        condition: b.condition,
        unlocked: b.unlocked,
      );
    }
    final status = await DatabaseHelper.instance.getBadgeStatus(UserProvider.instance.currentProfileId);
    _badges = defaultBadges
        .map((b) => Badge(
              id: b.id,
              name: b.name,
              icon: b.icon,
              condition: b.condition,
              unlocked: status[b.id] ?? false,
            ))
        .toList();
    _badgesLoaded = true;
    notifyListeners();
  }

  /// 按学习进度自动解锁勋章（闯关结算 / 每日刷新时调用）
  Future<void> refreshBadges() async {
    if (_badges.isEmpty) return;
    final user = UserProvider.instance.profile;
    if (user == null) return;

    final levelById = {for (final l in _levels) l.id: l};
    final records =
        await DatabaseHelper.instance.getRecords(UserProvider.instance.currentProfileId, );
    final quizCount =
        records.where((r) => r.type == 'quiz').length;

    Future<void> unlockIf(String id, bool cond) async {
      final badge = _badges.firstWhere((b) => b.id == id,
          orElse: () => Badge(id: id, name: '', icon: '', condition: ''));
      if (cond && !badge.unlocked) {
        badge.unlocked = true;
        await DatabaseHelper.instance
            .setBadgeUnlocked(
              UserProvider.instance.currentProfileId, id, unlocked: true);
      }
    }

    await unlockIf('b_pinyin',
        (levelById['k_l1']?.starCount ?? 0) >= 1);
    await unlockIf('b_words',
        (levelById['p_l1']?.starCount ?? 0) >= 2);
    await unlockIf('b_poet',
        (levelById['p_l2']?.starCount ?? 0) >= 2);
    await unlockIf(
        'b_reader', (levelById['p_l4']?.starCount ?? 0) >= 1);
    await unlockIf('b_champion', quizCount >= 10);
    // 坚持之星：连续 7 天且每天玩满 10 分钟
    await unlockIf('b_persist',
        user.continuousDays >= 7 &&
            UserProvider.instance.todayPlayedEnough);
    await unlockIf(
        'b_middle',
        user.stage == StudyStage.primary &&
            _levels.isNotEmpty &&
            _levels.every((l) => l.starCount >= 3));
    notifyListeners();
  }

  static String _dayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

/// 关卡结算结果
class QuizResult {
  final Level level;
  final int correct;
  final int total;
  final int stars;
  final int bonusScore;

  QuizResult({
    required this.level,
    required this.correct,
    required this.total,
    required this.stars,
    required this.bonusScore,
  });
}
