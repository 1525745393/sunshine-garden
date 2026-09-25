// 题库数据冒烟测试：校验 mock 题库结构与字段完整性
// 纯 Dart 数据校验，无平台通道依赖，可在 CI（flutter test）中直接运行
import 'package:flutter_test/flutter_test.dart';

import 'package:sunshine_garden/mock/question_bank.dart';

void main() {
  const stages = ['kindergarten', 'primary', 'middle'];

  for (final stage in stages) {
    group('学段 $stage', () {
      final levels = levelsForStage(stage);

      test('至少包含 1 个关卡', () {
        expect(levels.length, greaterThanOrEqualTo(1));
      });

      test('每关题目数量 >= 2', () {
        for (final level in levels) {
          expect(level.questions.length, greaterThanOrEqualTo(2),
              reason: '关卡 ${level.id} 题目过少');
        }
      });

      test('题目字段完整（题面/选项/答案/解析均非空）', () {
        for (final level in levels) {
          for (final q in level.questions) {
            expect(q.question.trim(), isNotEmpty, reason: '${q.id} 题面为空');
            // 选择题/阅读题必须有 2 个以上选项；填空/判断类题目无选项属正常
            if (q.options != null) {
              expect(q.options!.length, greaterThanOrEqualTo(2),
                  reason: '${q.id} 选项不足');
            }
            expect(q.answer.trim(), isNotEmpty, reason: '${q.id} 答案为空');
            expect(q.analysis.trim(), isNotEmpty, reason: '${q.id} 解析为空');
          }
        }
      });
    });
  }
}
