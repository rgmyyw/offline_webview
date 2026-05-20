import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/offline_const.dart';
import '../core/offline_web_manager.dart';
import '../server/local_server.dart';
import 'bis_name_matcher.dart';

/// [BisNameMatcher]的默认实现。
///
/// 从URL的`offweb`查询参数解析业务模块名称。如果对应的离线包
/// 存在于磁盘上，则构造指向本地`index.html`的`file://` URL。
/// 否则回退到原始在线URL。
class DefaultMatcher extends BisNameMatcher {
  /// bisName -> cur目录路径的缓存，由OfflineWebManager填充。
  static final Map<String, String> _curPathCache = {};

  /// bisName -> 预验证的 htmlPath（仅当文件存在时才缓存）。
  /// 在 [setCurPath] 时一次性完成 existsSync 检查，
  /// 避免每次 [matching] 都做磁盘 I/O 和路径拼接。
  static final Map<String, String> _htmlPathCache = {};

  /// 更新给定bisName的缓存cur路径，同时预验证index.html存在性。
  static void setCurPath(String bisName, String path) {
    _curPathCache[bisName] = path;
    final htmlPath = p.join(path, OfflineFileName.html);
    if (File(htmlPath).existsSync()) {
      _htmlPathCache[bisName] = htmlPath;
    } else {
      _htmlPathCache.remove(bisName);
    }
  }

  /// 移除给定bisName的缓存cur路径。
  static void removeCurPath(String bisName) {
    _curPathCache.remove(bisName);
    _htmlPathCache.remove(bisName);
  }

  /// 清除所有缓存的cur路径。
  static void clearCache() {
    _curPathCache.clear();
    _htmlPathCache.clear();
  }

  /// 获取给定bisName的缓存cur路径，如果未缓存则返回null。
  static String? getCurPath(String bisName) {
    return _curPathCache[bisName];
  }

  @override
  String matching(String url) {
    if (url.isEmpty) return url;

    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return url;
    }

    final bisName = uri.queryParameters[OfflineParam.offWeb];
    if (bisName == null || bisName.isEmpty) return url;

    if (OfflineWebManager.instance.isDisable(bisName)) return url;

    // 从缓存确认包存在
    final htmlPath = _htmlPathCache[bisName];
    if (htmlPath == null) return url;

    if (!File(htmlPath).existsSync()) {
      _htmlPathCache.remove(bisName);
      return url;
    }

    return _buildLocalUrl(uri);
  }

  /// 构造带有原始查询参数和 fragment 的 HTTP localhost URL。
  String _buildLocalUrl(Uri originalUri) {
    final bisName = originalUri.queryParameters[OfflineParam.offWeb];
    if (bisName == null) return originalUri.toString();

    final queryParams = Map<String, String>.from(originalUri.queryParameters);
    final originalHost = originalUri.host;
    if (originalHost.isNotEmpty) {
      queryParams[OfflineParam.offWebHost] = originalHost;
    }
    queryParams.remove(OfflineParam.offWeb);

    final result = LocalServer.instance.buildIndexUrl(
      bisName,
      queryParams: queryParams,
      fragment: originalUri.fragment,
    );
    return result ?? originalUri.toString();
  }

}
