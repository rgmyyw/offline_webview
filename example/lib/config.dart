/// 示例应用配置常量。
class AppConfig {
  /// 用于测试的业务名称。
  static const String testBisName = 'test-offline-package';

  /// 离线包服务器主机（Python 服务）。
  static const String serverHost = '192.168.1.62';

  ///  服务端口。
  static const int serverPort = 18730;

  /// 查询离线包更新的端点。
  static String get queryUrl => 'http://$serverHost:$serverPort/offweb';

  /// 下载包 zip 的端点。
  static String get packageUrl => 'http://$serverHost:$serverPort/package';

  /// 服务器基础 URL。
  static String get baseUrl => 'http://$serverHost:$serverPort';

  /// 是否启用 vConsole 调试面板，默认关闭。
  static bool enableVConsole = true;
}
