/// 题型枚举
enum QuestionType {
  choice('选择'),
  judge('判断'),
  fill('填空'),
  read('阅读理解');

  const QuestionType(this.label);
  final String label;

  static QuestionType fromName(String name) =>
      QuestionType.values.firstWhere((e) => e.name == name,
          orElse: () => QuestionType.choice);
}

/// 题目（题库结构，支持按学段/学科/单元/知识点/难度筛选）
class Question {
  final String id;
  final String stage; // 学段：primary / kindergarten / middle
  final String grade; // 如：一年级
  final String subject; // 学科：语文 / 数学
  final String unit; // 单元
  final List<String> knowledge; // 知识点
  final int difficulty; // 1-3
  final QuestionType type;
  final String question;
  final List<String>? options; // choice/read 使用
  final String answer; // 正确答案
  final String analysis; // 解析

  const Question({
    required this.id,
    required this.stage,
    required this.grade,
    required this.subject,
    required this.unit,
    required this.knowledge,
    required this.difficulty,
    required this.type,
    required this.question,
    this.options,
    required this.answer,
    required this.analysis,
  });

  /// 选项乱序：返回打乱后的选项索引序列（防作弊）
  List<int> shuffledOptionIndexes() {
    final idx = List<int>.generate(options?.length ?? 0, (i) => i);
    idx.shuffle();
    return idx;
  }

  factory Question.fromMap(Map<String, dynamic> map) => Question(
        id: map['id'] as String,
        stage: map['stage'] as String,
        grade: map['grade'] as String,
        subject: map['subject'] as String,
        unit: map['unit'] as String,
        knowledge: ((map['knowledge'] as String?) ?? '')
            .split(',')
            .where((e) => e.isNotEmpty)
            .toList(),
        difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
        type: QuestionType.fromName(map['type'] as String? ?? 'choice'),
        question: map['question'] as String,
        options: (map['options'] as String?) != null
            ? (map['options'] as String).split('|')
            : null,
        answer: map['answer'] as String,
        analysis: map['analysis'] as String,
      );
}
