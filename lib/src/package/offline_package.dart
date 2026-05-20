import '../core/offline_const.dart';
import '../server/local_server.dart';
import '../util/file_mgr.dart';

/// 离线包操作的静态辅助类。
///
/// 提供从URL提取业务名称、构建本地HTTP URL和管理磁盘缓存的实用方法。
class OfflinePackage {
  /// 从URL字符串中提取离线Web业务名称（bisName）。
  static String? getOffWebBisName(String urlStr) {
    if (urlStr.isEmpty) return null;

    try {
      final uri = Uri.parse(urlStr);
      final bisName = uri.queryParameters[OfflineParam.offWeb];
      if (bisName == null || bisName.isEmpty) return null;
      return bisName;
    } catch (_) {
      return null;
    }
  }

  /// 为离线包的 index.html 构建 HTTP localhost URL。
  ///
  /// 如需要则执行 `new -> cur` 文件夹交换，然后通过
  /// [LocalServer] 构造 HTTP URL。
  static Future<String> getFileURL(Uri webUrl) async {
    final bisName = webUrl.queryParameters[OfflineParam.offWeb] ?? '';
    if (bisName.isEmpty) return webUrl.toString();

    // 确保new文件夹交换到cur
    await FileMgr.doNewFolder2CurFolder(bisName);

    final server = LocalServer.instance;

    // 确保该 bisName 的本地服务器已启动
    if (!server.isRunning(bisName)) {
      await server.startForBisName(bisName);
    }

    // 构建查询参数：保留原始参数（除了offweb），添加offweb_host
    final queryParams = Map<String, String>.from(webUrl.queryParameters);
    final originalHost = webUrl.host;
    if (originalHost.isNotEmpty) {
      queryParams[OfflineParam.offWebHost] = originalHost;
    }
    queryParams.remove(OfflineParam.offWeb);

    return server.buildIndexUrl(
      bisName,
      queryParams: queryParams,
      fragment: webUrl.fragment,
    ) ?? webUrl.toString();
  }

  /// 删除给定[bisName]的所有磁盘缓存。
  static Future<bool> deleteDiskCache(String bisName) {
    return FileMgr.deleteDiskCache(bisName);
  }

  /// 删除所有业务模块的离线Web磁盘缓存。
  static Future<bool> deleteAllDiskCache() {
    return FileMgr.deleteAllDiskCache();
  }
}
