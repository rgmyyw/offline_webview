import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import 'off_web_log.dart';

/// 文件操作的实用类：解压、大小、重命名、删除、读取。
class FileUtil {
  /// 将[zipPath]处的文件解压到[destDir]。
  ///
  /// 成功返回`true`，失败返回`false`。
  static Future<bool> unzipFile(String zipPath, String destDir) async {
    const tag = 'FileUtil';
    try {
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      Logger.d(tag, '解压ZIP: ${archive.files.length}个文件 -> $destDir');

      for (final file in archive) {
        final filePath = '$destDir/${file.name}';
        if (file.isFile) {
          final outputFile = File(filePath);
          await outputFile.parent.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }
      return true;
    } catch (e, stack) {
      Logger.e(tag, '解压失败: $e, 堆栈: $stack');
      return false;
    }
  }

  /// 返回[path]处文件的大小（千字节）。
  ///
  /// 如果文件不存在则返回`-1`。
  static double getFileSize(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        return bytes / 1024.0;
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  /// 将文件或目录[entity]重命名为[newName]。
  ///
  /// [newName]应该只是新名称，不是完整路径。
  /// 成功返回`true`。
  static bool rename(FileSystemEntity entity, String newName) {
    const tag = 'FileUtil';
    try {
      final parentPath = entity.parent.path;
      final newPath = '$parentPath/$newName';
      entity.renameSync(newPath);
      return true;
    } catch (e) {
      Logger.e(tag, 'rename失败: ${entity.path} -> $newName, error: $e');
      return false;
    }
  }

  /// 异步删除目录。
  ///
  /// 成功返回`true`，失败返回`false`。
  static Future<bool> deleteDir(Directory dir) async {
    try {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 同步删除目录。
  ///
  /// 成功返回`true`，失败返回`false`。
  static bool deleteDirSync(Directory dir) {
    try {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 将[path]处的文件读取为字符串（UTF-8编码）。
  ///
  /// 如果文件不存在或无法读取则返回`null`。
  static String? readFileAsString(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        // 使用 UTF-8 编码读取，避免系统默认编码问题
        return file.readAsStringSync(encoding: const Utf8Codec());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 检查[path]处文件或目录是否存在。
  static bool exists(String path) {
    return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
  }
}
