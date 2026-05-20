import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/offline_const.dart';
import '../util/file_mgr.dart';
import '../util/file_util.dart';

/// 在启动时执行new-to-cur版本替换的任务。
///
/// 迭代所有业务模块目录并应用：
/// - 如果`new`和`cur`都存在：将`cur` -> `old`，然后`new` -> `cur`
/// - 如果只有`new`存在：将`new` -> `cur`
/// - 如果存在`old`目录则删除
class CheckVersionTask {
  /// 运行所有业务模块的版本检查任务。
  static Future<void> run() async {
    final bisNames = await FileMgr.getAllBisNames();

    for (final bisName in bisNames) {
      await _checkVersion(bisName);
    }
  }

  /// 对单个业务模块执行版本检查。
  static Future<void> _checkVersion(String bisName) async {
    final bisDir = await FileMgr.getBisDir(bisName);
    final curDir = Directory(p.join(bisDir, OfflineDirName.cur));
    final newDir = Directory(p.join(bisDir, OfflineDirName.newDir));
    final oldDir = Directory(p.join(bisDir, OfflineDirName.old));

    final curExists = curDir.existsSync();
    final newExists = newDir.existsSync();

    if (newExists && curExists) {
      // 两个都存在：cur -> old, new -> cur
      await FileUtil.deleteDir(oldDir);
      FileUtil.rename(curDir, OfflineDirName.old);
      FileUtil.rename(newDir, OfflineDirName.cur);
    } else if (newExists) {
      // 只有new：new -> cur
      FileUtil.rename(newDir, OfflineDirName.cur);
    }

    // 如果旧目录仍然存在则删除
    if (oldDir.existsSync()) {
      await FileUtil.deleteDir(oldDir);
    }
  }
}
