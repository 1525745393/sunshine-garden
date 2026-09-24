import 'question.dart';

/// 关卡
class Level {
  final String id;
  final String stage;
  final String subject;
  final String unit;
  final String name;
  final String description;
  final List<Question> questions;

  /// 星级：0=未玩，1/2/3=星级
  int starCount;
  bool unlocked;

  Level({
    required this.id,
    required this.stage,
    required this.subject,
    required this.unit,
    required this.name,
    required this.description,
    required this.questions,
    this.starCount = 0,
    this.unlocked = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'stage': stage,
        'subject': subject,
        'unit': unit,
        'name': name,
        'star_count': starCount,
        'unlocked': unlocked ? 1 : 0,
      };

  factory Level.fromMap(Map<String, dynamic> map) => Level(
        id: map['id'] as String,
        stage: map['stage'] as String,
        subject: map['subject'] as String,
        unit: map['unit'] as String,
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        questions: const [],
        starCount: (map['star_count'] as num?)?.toInt() ?? 0,
        unlocked: (map['unlocked'] as num?)?.toInt() == 1,
      );
}
