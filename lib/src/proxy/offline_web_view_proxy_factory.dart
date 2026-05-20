import '../core/offline_web_manager.dart';
import '../widget/offline_web_view_controller.dart';
import 'empty_offline_web_view_proxy.dart';
import 'offline_web_view_proxy.dart';
import 'offline_web_view_proxy_impl.dart';

/// 用于创建适当的[IOfflineWebViewProxy]实例的工厂。
///
/// 如果[OfflineWebManager]已初始化则返回[OfflineWebViewProxy]，
/// 否则返回不做任何操作的[EmptyOfflineWebViewProxy]。
class OfflineWebViewProxyFactory {
  /// 为给定的[controller]创建代理。
  ///
  /// 如果[OfflineWebManager]已初始化，返回一个完整的代理来解析离线内容。
  /// 否则返回一个no-op代理。
  static IOfflineWebViewProxy create({
    required OfflineWebViewController controller,
  }) {
    final manager = OfflineWebManager.instance;
    if (manager.isInit) {
      return OfflineWebViewProxy(
        controller: controller,
      );
    }
    return EmptyOfflineWebViewProxy();
  }
}
