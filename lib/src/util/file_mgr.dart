import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../core/offline_const.dart';
import 'file_util.dart';

/// 管理离线Web包的目录结构。
///
/// 基础目录下的布局：
/// ```
/// <appDocuments>/offline_web/
///   <bisName>/
///     cur/          - 当前活动包
///     new/          - 新下载的包，等待交换
///     old/          - 上一个包，等待清理
///     temp/         - 临时解压文件夹
/// ```
class FileMgr {
  static String? _basePath;

  /// 覆盖基础路径（用于测试）。
  static void setBasePath(String path) {
    _basePath = path;
  }

  /// 返回所有离线Web数据的根目录。
  ///
  /// 默认为`<appDocuments>/offline_web`。
  static Future<String> getBaseDir() async {
    if (_basePath != null) return _basePath!;
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, kOfflineWebRootDir);
  }

  /// 返回特定业务模块的目录：`<base>/<bisName>`。
  static Future<String> getBisDir(String bisName) async {
    final base = await getBaseDir();
    return p.join(base, bisName);
  }

  /// 返回当前HTML文件的路径：`<bisDir>/cur/index.html`。
  static Future<String> getPath(String bisName) async {
    final bisDir = await getBisDir(bisName);
    return p.join(bisDir, OfflineDirName.cur, OfflineFileName.html);
  }

  /// 从`<bisDir>/cur/.offweb.json`读取当前版本。
  ///
  /// 如果配置文件不存在或无法解析则返回`'0'`。
  static Future<String> getCurVersion(String bisName) async {
    final bisDir = await getBisDir(bisName);
    final configPath =
        p.join(bisDir, OfflineDirName.cur, OfflineFileName.config);
    return _readVersionFromConfig(configPath);
  }

  /// 从`<bisDir>/new/.offweb.json`读取新版本。
  ///
  /// 如果配置文件不存在或无法解析则返回`'0'`。
  static Future<String> getNewVersion(String bisName) async {
    final bisDir = await getBisDir(bisName);
    final configPath =
        p.join(bisDir, OfflineDirName.newDir, OfflineFileName.config);
    return _readVersionFromConfig(configPath);
  }

  /// 从配置文件读取版本字符串。
  static Future<String> _readVersionFromConfig(String configPath) async {
    final content = FileUtil.readFileAsString(configPath);
    if (content == null) return '0';
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return json['version']?.toString() ?? '0';
    } catch (e) {
      return '0';
    }
  }

  /// 为[bisName]解压zip文件并放置到相应文件夹。
  ///
  /// 如果`cur`不存在：直接解压到`cur`。
  /// 如果`cur`存在：删除现有的`new`，解压到`new`。
  ///
  /// 成功时返回`true`。
  static Future<bool> doZipToNewFolder(
      String bisName, String zipPath) async {
    try {
      final bisDir = await getBisDir(bisName);
      final curDir = Directory(p.join(bisDir, OfflineDirName.cur));
      final newDir = Directory(p.join(bisDir, OfflineDirName.newDir));
      final tempDir = Directory(p.join(bisDir, OfflineDirName.temp));

      // 清理临时目录
      await FileUtil.deleteDir(tempDir);
      await tempDir.create(recursive: true);

      // 解压到temp
      final success = await FileUtil.unzipFile(zipPath, tempDir.path);
      if (!success) return false;

      if (!curDir.existsSync()) {
        // 还没有当前版本 — 将temp移到cur
        final moved = FileUtil.rename(tempDir, OfflineDirName.cur);
        return moved;
      } else {
        // 当前版本存在 — 用temp替换new
        await FileUtil.deleteDir(newDir);
        final moved = FileUtil.rename(tempDir, OfflineDirName.newDir);
        return moved;
      }
    } catch (e) {
      return false;
    }
  }

  /// 将`new`文件夹交换到`cur`，先将`cur`移到`old`。
  ///
  /// 成功时返回`true`。
  static Future<bool> doNewFolder2CurFolder(String bisName) async {
    try {
      final bisDir = await getBisDir(bisName);
      final curDir = Directory(p.join(bisDir, OfflineDirName.cur));
      final newDir = Directory(p.join(bisDir, OfflineDirName.newDir));
      final oldDir = Directory(p.join(bisDir, OfflineDirName.old));

      if (!newDir.existsSync()) return false;

      // 如果cur存在，将其移到old（覆盖之前的old）
      if (curDir.existsSync()) {
        await FileUtil.deleteDir(oldDir);
        FileUtil.rename(curDir, OfflineDirName.old);
      }

      // 将new移到cur
      FileUtil.rename(newDir, OfflineDirName.cur);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 删除[bisName]的`old`文件夹。
  static Future<void> deleteOldFolder(String bisName) async {
    final bisDir = await getBisDir(bisName);
    final oldDir = Directory(p.join(bisDir, OfflineDirName.old));
    await FileUtil.deleteDir(oldDir);
  }

  /// 删除特定业务模块的所有缓存数据。
  ///
  /// 成功时返回`true`。
  static Future<bool> deleteDiskCache(String bisName) async {
    final bisDir = await getBisDir(bisName);
    final dir = Directory(bisDir);
    return FileUtil.deleteDir(dir);
  }

  /// 删除所有业务模块的所有离线Web缓存数据。
  ///
  /// 成功时返回`true`。
  static Future<bool> deleteAllDiskCache() async {
    final baseDir = await getBaseDir();
    final dir = Directory(baseDir);
    return FileUtil.deleteDir(dir);
  }

  /// 列出所有业务模块名称（基础目录下子目录）。
  static Future<List<String>> getAllBisNames() async {
    try {
      final baseDir = await getBaseDir();
      final dir = Directory(baseDir);
      if (!dir.existsSync()) return [];

      final names = <String>[];
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          names.add(p.basename(entity.path));
        }
      }
      return names;
    } catch (e) {
      return [];
    }
  }

  /// 获取指定业务模块的包大小（字节数）。
  static Future<int> getPackageSize(String bisName) async {
    try {
      final bisDir = await getBisDir(bisName);
      final curDir = Directory(p.join(bisDir, OfflineDirName.cur));
      if (!curDir.existsSync()) return 0;
      return _calcDirSize(curDir);
    } catch (e) {
      return 0;
    }
  }

  /// 递归计算目录大小。
  static int _calcDirSize(Directory dir) {
    int size = 0;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        size += entity.lengthSync();
      }
    }
    return size;
  }
}
