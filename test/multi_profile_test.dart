// 多孩子档案测试：校验业务行 id 前缀透明（纯 Dart，无平台通道）
import 'package:flutter_test/flutter_test.dart';

import 'package:sunshine_garden/db/database_helper.dart';

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
}
