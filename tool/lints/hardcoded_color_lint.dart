// 自定义 lint：禁止在 lib/ 业务代码中硬编码颜色值
// 颜色应统一使用 lib/theme/app_theme.dart 的 AppColors 常量
// 用法：dart run tool/lints/hardcoded_color_lint.dart
// 检出违规时 stdout 输出含 "HardcodedColor" 的行并返回非 0 退出码
import 'dart:io';

/// 仅允许包含颜色定义的主题文件（主题本身必然包含色值）
const themeFile = 'lib/theme/app_theme.dart';

/// 硬编码颜色构造模式：Color(0x...) / fromARGB / fromRGBO / fromRGB
final RegExp colorPattern = RegExp(
  r'Color\((0x[0-9A-Fa-f]+|fromARGB|fromRGBO|fromRGB)',
);

void main() {
  final root = Directory('lib');
  if (!root.existsSync()) {
    stderr.writeln('未找到 lib/ 目录，请在项目根目录运行本工具');
    exit(1);
  }

  var violations = 0;
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    if (file.path == themeFile) continue;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trimLeft().startsWith('//')) continue;
      if (!colorPattern.hasMatch(line)) continue;
      violations++;
      print('HardcodedColor: ${file.path}:${i + 1}: ${line.trim()}');
    }
  }

  if (violations > 0) {
    stderr.writeln('发现 $violations 处硬编码颜色，请改用 AppColors 主题常量');
    exit(1);
  }
  print('✅ 未检测到硬编码颜色');
}
