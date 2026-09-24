/// 学习记录（时间线条目）
class StudyRecord {
  final String id;
  final String dayKey; // yyyy-MM-dd
  final DateTime createdAt;

  /// 类型：quiz（闯关）/ task（任务）/ reward（兑换）
  final String type;
  final String title;
  final String detail;
  final int scoreChange; // 积分变化（可为 0）

  StudyRecord({
    required this.id,
    required this.dayKey,
    required this.createdAt,
    required this.type,
    required this.title,
    required this.detail,
    this.scoreChange = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'day_key': dayKey,
        'created_at': createdAt.toIso8601String(),
        'type': type,
        'title': title,
        'detail': detail,
        'score_change': scoreChange,
      };

  factory StudyRecord.fromMap(Map<String, dynamic> map) => StudyRecord(
        id: map['id'] as String,
        dayKey: map['day_key'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        type: map['type'] as String,
        title: map['title'] as String,
        detail: map['detail'] as String? ?? '',
        scoreChange: (map['score_change'] as num?)?.toInt() ?? 0,
      );
}
