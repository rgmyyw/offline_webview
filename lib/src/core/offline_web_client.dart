import 'package:offline_webview/offline_webview.dart';

/// 离线Web SDK的静态入口点.
///
/// 提供初始化SDK、检查包、管理禁用列表的顶层方法.
class OfflineWebClient {
  /// 使用给定的[params]初始化离线Web SDK.
  ///
  /// 调用[OfflineWebManager.init]初始化, 然后启动
  /// 初始化任务(版本检查、缓存刷新、预下载).
  static Future<void> init(OfflineParams params) async {
    final manager = OfflineWebManager.instance;
    await manager.init(params);

    if (manager.isInit) {
      await manager.taskManager.startInitTask();
      // 关键修复：在startInitTask完成后刷新所有缓存
      // 这确保DefaultMatcher的_curPathCache被正确填充，
      // 使离线内容在首次加载时就能被解析为本地file:// URL
      await manager.refreshAllCurPathCache();
    }
  }

  /// 检查并更新给定[bisName]的离线包.
  ///
  /// 委托给[OfflineWebManager.checkPackage].
  static void checkPackage(String bisName) {
    OfflineWebManager.instance.checkPackage(bisName, null);
  }

  /// 清理所有离线Web缓存数据.
  ///
  /// 委托给[OfflineWebManager.clean].
  static Future<void> clean() async {
    await OfflineWebManager.instance.clean();
  }

  /// 清理指定[bisName]的离线Web缓存数据.
  static Future<void> cleanBisName(String bisName) async {
    await OfflineWebManager.instance.cleanBisName(bisName);
  }

  /// 将业务模块添加到动态禁用列表.
  ///
  /// 委托给[OfflineWebManager.addToDisableList].
  static void addToDisableList(String bisName) {
    OfflineWebManager.instance.addToDisableList(bisName);
  }

  /// 更新请求接口而无需重新初始化SDK。
  ///
  /// 使用此方法可按页面切换服务器端点。
  static void setRequest(IOfflineRequest request) {
    OfflineWebManager.instance.setRequest(request);
  }
}
