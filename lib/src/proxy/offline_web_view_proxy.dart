/// 离线Web系统中WebView代理的抽象接口。
///
/// 提供统一的API来加载带有离线支持的URL。
/// 实现类处理离线到本地URL的解析和页面生命周期。
abstract class IOfflineWebViewProxy {
  /// 与此代理关联的业务模块名称。
  String get bisName;

  /// 加载给定的[url]，如果离线内容可用则将其解析为本地file URL。
  /// 返回解析后的URL。
  String loadUrl(String url);

  /// 使用预解析结果初始化代理状态，不触发URL加载。
  ///
  /// 用于配合 [OfflineWebView] 的 `initialUrlRequest` 优化路径：
  /// WebView 已通过 initialUrlRequest 直接加载预解析的 file:// URL，
  /// 代理只需初始化内部状态（bisName、isOffline 等），
  /// 无需再通过 loadUrl 触发二次加载。
  void initialize(String originalUrl, String resolvedUrl);

  /// 重新加载此代理WebView的当前URL。
  void reLoadUrl();

  /// 清理与此代理关联的资源。
  void destroy();
}
