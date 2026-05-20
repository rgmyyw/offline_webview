import 'dart:io';

import 'package:path/path.dart' as p;

/// HTML 缓存。
///
/// 将 WebView 首次渲染后的完整 HTML 保存到离线包 cur 目录，
/// 后续访问时通过 loadData 加载缓存，消除白屏等待。
/// 缓存文件存储在 cur 目录下，离线包更新时自动失效。
class HtmlCache {
  static const _cacheFileName = '.html_cache';

  /// 同步读取缓存 HTML。不存在或读取失败返回 null。
  static String? loadSync(String curDirPath) {
    final file = File(p.join(curDirPath, _cacheFileName));
    if (!file.existsSync()) return null;
    try {
      return file.readAsStringSync();
    } catch (_) {
      return null;
    }
  }

  /// 异步保存 HTML 到缓存。
  static Future<void> save(String curDirPath, String html) async {
    final file = File(p.join(curDirPath, _cacheFileName));
    await file.writeAsString(html);
  }

  /// 删除指定目录的 HTML 缓存。
  static Future<void> delete(String curDirPath) async {
    final file = File(p.join(curDirPath, _cacheFileName));
    if (file.existsSync()) await file.delete();
  }
}
