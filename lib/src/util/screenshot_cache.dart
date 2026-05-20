import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/offline_const.dart';

/// WebView 截图缓存。
///
/// 将 WebView 页面截图保存到磁盘，下次打开时先显示截图，
/// 后台 WebView 加载完毕后切换，消除白屏。
class ScreenshotCache {
  static String? _baseDir;

  static void setBaseDir(String path) {
    _baseDir = path;
  }

  static Future<String> _getDir() async {
    if (_baseDir != null) return _baseDir!;
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, kOfflineWebRootDir, 'screenshots');
  }

  /// 保存截图到磁盘。
  static Future<void> save(String bisName, Uint8List pngData) async {
    final dir = await _getDir();
    await Directory(dir).create(recursive: true);
    final file = File(p.join(dir, '$bisName.png'));
    await file.writeAsBytes(pngData);
  }

  /// 读取缓存的截图文件。不存在则返回 null。
  static Future<File?> load(String bisName) async {
    final dir = await _getDir();
    final file = File(p.join(dir, '$bisName.png'));
    return file.existsSync() ? file : null;
  }

  /// 指定 bisName 是否有缓存截图。
  static Future<bool> exists(String bisName) async {
    final file = await load(bisName);
    return file != null;
  }

  /// 删除指定 bisName 的缓存截图。
  static Future<void> delete(String bisName) async {
    final dir = await _getDir();
    final file = File(p.join(dir, '$bisName.png'));
    if (file.existsSync()) await file.delete();
  }

  /// 删除所有缓存截图。
  static Future<void> deleteAll() async {
    final dir = await _getDir();
    final d = Directory(dir);
    if (d.existsSync()) await d.delete(recursive: true);
  }
}
