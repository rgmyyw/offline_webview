import '../core/offline_const.dart';
import '../core/offline_web_manager.dart';
import '../match/off_web_rule_util.dart';
import '../server/local_server.dart';
import '../widget/offline_web_view_controller.dart';
import 'offline_web_view_proxy.dart';

/// 拦截WebView URL加载并解析离线内容的代理。
///
/// 当调用[loadUrl]时，此代理：
/// 1. 通过规则匹配添加离线查询参数
/// 2. 检查URL是否应使用离线内容
/// 3. 如果离线包存在则解析为本地file:// URL
/// 4. 在后台触发包更新检查
class OfflineWebViewProxy implements IOfflineWebViewProxy {
  final OfflineWebViewController _controller;
  String _bisName = '';
  String _originalUrl = '';
  bool _isOffline = false;
  bool _destroyed = false;

  OfflineWebViewProxy({
    required OfflineWebViewController controller,
  })  : _controller = controller;

  @override
  String get bisName => _bisName;

  /// 代理当前是否提供离线内容。
  bool get isOffline => _isOffline;

  @override
  void initialize(String originalUrl, String resolvedUrl) {
    if (_destroyed) return;

    _originalUrl = originalUrl;
    _isOffline = resolvedUrl != originalUrl && LocalServer.isLocalServerUrl(resolvedUrl);

    try {
      final uri = Uri.parse(originalUrl);
      _bisName = uri.queryParameters[OfflineParam.offWeb] ?? '';
    } catch (_) {}

    if (_bisName.isEmpty) return;

    final manager = OfflineWebManager.instance;
    if (manager.isDisable(_bisName)) return;

    manager.pageManager.addPage(this);

    // 始终触发后台检查以获取各阶段耗时数据
    _checkPackageAsync(_bisName);
  }

  @override
  String loadUrl(String url) {
    if (_destroyed || url.isEmpty) return url;

    _originalUrl = url;

    final manager = OfflineWebManager.instance;
    if (!manager.isInit) return url;

    final urlWithParam =
        OffWebRuleUtil.addOfflineParam(url, manager.ruleConfig);

    if (!urlWithParam.contains(OfflineParam.offWeb)) return url;
    if (!urlWithParam.startsWith('http://') &&
        !urlWithParam.startsWith('https://')) {
      return url;
    }

    try {
      final uri = Uri.parse(urlWithParam);
      _bisName = uri.queryParameters[OfflineParam.offWeb] ?? '';
    } catch (_) {
      return url;
    }

    if (_bisName.isEmpty) return url;

    if (manager.isDisable(_bisName)) return url;

    final matcher = manager.matcher;
    final resolvedUrl = matcher.matching(urlWithParam);

    _isOffline =
        resolvedUrl != urlWithParam && LocalServer.isLocalServerUrl(resolvedUrl);

    if (!_isOffline) {
      _checkPackageAsync(_bisName);
    }

    if (_bisName.isNotEmpty) {
      manager.pageManager.addPage(this);
    }

    return _isOffline ? resolvedUrl : url;
  }

  @override
  void reLoadUrl() {
    if (_destroyed || _originalUrl.isEmpty) return;
    loadUrl(_originalUrl);
    _controller.reloadOfflineWeb();
  }

  @override
  void destroy() {
    _destroyed = true;
    final manager = OfflineWebManager.instance;
    if (_bisName.isNotEmpty) {
      manager.pageManager.remove(this);
    }
  }

  /// 为给定bisName触发后台包检查。
  void _checkPackageAsync(String bisName) {
    Future.microtask(() {
      OfflineWebManager.instance.checkPackage(bisName, null);
    });
  }
}
