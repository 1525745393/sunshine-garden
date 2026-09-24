/// 错题记录
class Mistake {
  final String id; // 题目 id
  final String questionText;
  final String userAnswer;
  final String correctAnswer;
  final String analysis;
  final DateTime addedAt;

  /// 复习节点：答错后第 1/3/7 天（v1.0 仅记录，v1.1 启用遗忘曲线提醒）
  DateTime nextReviewAt;

  /// 已重做正确则移出错题本
  bool resolved;

  Mistake({
    required this.id,
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
    required this.analysis,
    required this.addedAt,
    required this.nextReviewAt,
    this.resolved = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'question_text': questionText,
        'user_answer': userAnswer,
        'correct_answer': correctAnswer,
        'analysis': analysis,
        'added_at': addedAt.toIso8601String(),
        'next_review_at': nextReviewAt.toIso8601String(),
        'resolved': resolved ? 1 : 0,
      };

  factory Mistake.fromMap(Map<String, dynamic> map) => Mistake(
        id: map['id'] as String,
        questionText: map['question_text'] as String,
        userAnswer: map['user_answer'] as String? ?? '',
        correctAnswer: map['correct_answer'] as String,
        analysis: map['analysis'] as String? ?? '',
        addedAt: DateTime.parse(map['added_at'] as String),
        nextReviewAt: DateTime.parse(map['next_review_at'] as String),
        resolved: (map['resolved'] as num?)?.toInt() == 1,
      );
}
