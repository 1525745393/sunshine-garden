import 'dart:convert';
import 'dart:io';

/// 更新信息
class UpdateInfo {
  final String latestVersion; // 如 1.3.0
  final String releaseNotes; // 更新说明
  final String downloadUrl; // universal APK 下载地址
  final bool hasUpdate;

  UpdateInfo({
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.hasUpdate,
  });
}

/// 检查更新服务：查询 GitHub Releases 最新版并对比本地版本
/// 仅获取版本号与下载链接，不收集任何儿童数据
class UpdateChecker {
  static const _apiUrl =
      'https://api.github.com/repos/1525745393/sunshine-garden/releases/latest';

  /// 当前版本（由 PackageInfo 注入）
  static String currentVersion = '0.0.0';

  /// 检查更新；网络异常或解析失败返回 null（静默处理，不打扰使用）
  static Future<UpdateInfo?> check() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(_apiUrl));
      req.headers.set('Accept', 'application/vnd.github+json');
      req.headers.set('User-Agent', 'sunshine-garden');
      final res = await req.close();
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final tag = (data['tag_name'] as String?) ?? '';
      final latest = tag.replaceFirst(RegExp('^v'), '');
      final notes = (data['body'] as String?) ?? '';
      final assets = (data['assets'] as List?) ?? const [];
      // 优先 universal APK（app-release.apk），否则取第一个 APK
      String url = '';
      for (final a in assets) {
        final name = (a['name'] as String?) ?? '';
        final dl = (a['browser_download_url'] as String?) ?? '';
        if (name == 'app-release.apk') {
          url = dl;
          break;
        }
        if (url.isEmpty && name.endsWith('.apk')) url = dl;
      }

      return UpdateInfo(
        latestVersion: latest,
        releaseNotes: notes,
        downloadUrl: url,
        hasUpdate: _compare(latest, currentVersion) > 0,
      );
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// 语义版本比较：major.minor.patch（+build 忽略）
  static int _compare(String a, String b) {
    final pa = _parts(a);
    final pb = _parts(b);
    for (var i = 0; i < 3; i++) {
      if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
    }
    return 0;
  }

  static List<int> _parts(String v) {
    final clean = v.split('+').first.split('-').first;
    final segs = clean.split('.');
    return List<int>.generate(
      3,
      (i) => int.tryParse(i < segs.length ? segs[i] : '0') ?? 0,
    );
  }
}
