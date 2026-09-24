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

/// 用户档案（单孩子档案，v1.0 仅一条）
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
      );
}
