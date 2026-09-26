// 多孩子档案测试：校验业务行 id 前缀透明（纯 Dart，无平台通道）
import 'package:flutter_test/flutter_test.dart';

import 'package:sunshine_garden/db/database_helper.dart';
import 'package:sunshine_garden/models/mistake.dart';

void main() {
  group('多孩子档案 id 前缀', () {
    test('写入 id 加档案前缀', () {
      expect(DatabaseHelper.pid('user_a', 'primary-chinese-u1'),
          'user_a:primary-chinese-u1');
      expect(DatabaseHelper.pid('user_b', 'primary-chinese-u1'),
          'user_b:primary-chinese-u1');
    });

    test('读取时还原原始 id（仅剥本档案前缀）', () {
      expect(
          DatabaseHelper.unpid('user_a', 'user_a:primary-chinese-u1'),
          'primary-chinese-u1');
      // 其他档案的前缀不误剥
      expect(
          DatabaseHelper.unpid('user_b', 'user_a:primary-chinese-u1'),
          'user_a:primary-chinese-u1');
      // 无前缀数据（v1.4 旧库）原样返回
      expect(DatabaseHelper.unpid('user_a', 'primary-chinese-u1'),
          'primary-chinese-u1');
    });
  });

  group('错题知识点字段（v1.6 薄弱分析）', () {
    test('fromMap 缺 knowledge 时默认空串（旧库兼容）', () {
      final m = Mistake.fromMap({
        'id': 'q1',
        'question_text': '题',
        'user_answer': '',
        'correct_answer': 'A',
        'analysis': '',
        'added_at': '2026-01-01T00:00:00.000',
        'next_review_at': '2026-01-02T00:00:00.000',
        'resolved': 0,
      });
      expect(m.knowledge, '');
    });

    test('knowledge 往返保留', () {
      final m = Mistake(
        id: 'q1',
        questionText: '题',
        userAnswer: 'B',
        correctAnswer: 'A',
        analysis: '解析',
        addedAt: DateTime(2026),
        nextReviewAt: DateTime(2026, 1, 2),
        knowledge: '字词、拼音',
      );
      final map = m.toMap();
      expect(map['knowledge'], '字词、拼音');
    });
  });
}
