import '../proxy/offline_web_view_proxy.dart';

/// 管理所有活动的离线WebView代理。
///
/// 按业务模块名称跟踪代理，以便
/// 当离线包更新时，可以重新加载相应的WebView。
class OfflinePageManager {
  final List<IOfflineWebViewProxy> _proxies = [];

  /// 将代理添加到管理列表。
  void addPage(IOfflineWebViewProxy proxy) {
    if (proxy.bisName.isEmpty) return;
    // 避免重复
    if (_proxies.any((p) => p.bisName == proxy.bisName && identical(p, proxy))) {
      return;
    }
    _proxies.add(proxy);
  }

  /// 从管理列表中移除代理。
  void remove(IOfflineWebViewProxy proxy) {
    _proxies.remove(proxy);
  }

  /// 重新加载与给定[bisName]关联的所有WebView。
  ///
  /// 当离线包更新且相应的WebView需要切换到新的本地内容时调用。
  void reload(String bisName) {
    for (final proxy in _proxies) {
      if (proxy.bisName == bisName) {
        proxy.reLoadUrl();
      }
    }
  }
}
