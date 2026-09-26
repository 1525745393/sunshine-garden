/// 学段枚举
enum StudyStage {
  kindergarten('幼儿园'),
  primary('小学'),
  middle('初中');

  const StudyStage(this.label);
  final String label;

  /// 默认每日可用时长（分钟）
  int get defaultDailyMinutes => switch (this) {
        StudyStage.kindergarten => 10,
        StudyStage.primary => 20,
        StudyStage.middle => 30,
      };
}

/// 用户档案（v1.5 多孩子：每个档案一行，独立学习数据）
class UserProfile {
  final String id;
  final String nickname;
  StudyStage stage;
  String grade;
  int totalScore;
  int continuousDays; // 连续打卡天数
  DateTime? lastActiveDate; // 最近活跃日期
  String? lastActiveDayKey; // yyyy-MM-dd，用于跨日判断

  // 家长设置
  int dailyMinutes; // 每日总时长（分钟）
  bool soundEnabled;
  bool animationEnabled;
  bool darkMode;
  int dailyTargetScore; // 每日目标积分（v1.3，0=未设置）
  bool filterCurrentStage; // 内容过滤：仅当前学段关卡（v1.3）
  int dailyScoreLimit; // 每日积分上限（v1.4，0=不限，防刷简单题）
  bool pomodoroEnabled; // 番茄钟开关（v1.4）
  int focusMinutes; // 单次学习时长（分钟，默认 15）
  int breakMinutes; // 休息时长（分钟，默认 3）
  int allowedStartHour; // 允许学习时间段起（v1.4，0-23，默认 0）
  int allowedEndHour; // 允许学习时间段止（v1.4，0-24，默认 24=全天）

  UserProfile({
    required this.id,
    required this.nickname,
    required this.stage,
    required this.grade,
    this.totalScore = 0,
    this.continuousDays = 0,
    this.lastActiveDate,
    this.lastActiveDayKey,
    int? dailyMinutes,
    this.soundEnabled = true,
    this.animationEnabled = true,
    this.darkMode = false,
    this.dailyTargetScore = 0,
    this.filterCurrentStage = false,
    this.dailyScoreLimit = 0,
    this.pomodoroEnabled = true,
    this.focusMinutes = 15,
    this.breakMinutes = 3,
    this.allowedStartHour = 0,
    this.allowedEndHour = 24,
  }) : dailyMinutes = dailyMinutes ?? stage.defaultDailyMinutes;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nickname': nickname,
        'stage': stage.name,
        'grade': grade,
        'total_score': totalScore,
        'continuous_days': continuousDays,
        'last_active_date': lastActiveDate?.toIso8601String(),
        'last_active_day_key': lastActiveDayKey,
        'daily_minutes': dailyMinutes,
        'sound_enabled': soundEnabled ? 1 : 0,
        'animation_enabled': animationEnabled ? 1 : 0,
        'dark_mode': darkMode ? 1 : 0,
        'daily_target_score': dailyTargetScore,
        'filter_current_stage': filterCurrentStage ? 1 : 0,
        'daily_score_limit': dailyScoreLimit,
        'pomodoro_enabled': pomodoroEnabled ? 1 : 0,
        'focus_minutes': focusMinutes,
        'break_minutes': breakMinutes,
        'allowed_start_hour': allowedStartHour,
        'allowed_end_hour': allowedEndHour,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        nickname: map['nickname'] as String,
        stage: StudyStage.values.firstWhere(
          (e) => e.name == map['stage'],
          orElse: () => StudyStage.primary,
        ),
        grade: map['grade'] as String? ?? '一年级',
        totalScore: (map['total_score'] as num?)?.toInt() ?? 0,
        continuousDays: (map['continuous_days'] as num?)?.toInt() ?? 0,
        lastActiveDate: map['last_active_date'] != null
            ? DateTime.tryParse(map['last_active_date'] as String)
            : null,
        lastActiveDayKey: map['last_active_day_key'] as String?,
        dailyMinutes: (map['daily_minutes'] as num?)?.toInt(),
        soundEnabled: (map['sound_enabled'] as num?)?.toInt() == 1,
        animationEnabled: (map['animation_enabled'] as num?)?.toInt() == 1,
        darkMode: (map['dark_mode'] as num?)?.toInt() == 1,
        dailyTargetScore: (map['daily_target_score'] as num?)?.toInt() ?? 0,
        filterCurrentStage: (map['filter_current_stage'] as num?)?.toInt() == 1,
        dailyScoreLimit: (map['daily_score_limit'] as num?)?.toInt() ?? 0,
        pomodoroEnabled:
            (map['pomodoro_enabled'] as num?)?.toInt() != 0,
        focusMinutes: (map['focus_minutes'] as num?)?.toInt() ?? 15,
        breakMinutes: (map['break_minutes'] as num?)?.toInt() ?? 3,
        allowedStartHour: (map['allowed_start_hour'] as num?)?.toInt() ?? 0,
        allowedEndHour: (map['allowed_end_hour'] as num?)?.toInt() ?? 24,
      );
}
