import '../util/file_mgr.dart';

/// 删除所有离线Web缓存数据的任务。
class CleanTask {
  /// 删除所有离线Web磁盘缓存。
  static Future<void> run() async {
    await FileMgr.deleteAllDiskCache();
  }
}
