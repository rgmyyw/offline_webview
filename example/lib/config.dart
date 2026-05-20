/// 示例应用配置常量。
class AppConfig {
  /// 用于测试的业务名称。
  static const String testBisName = 'test-offline-package';

  /// 客户端连接的本地服务器主机。
  static const String serverHost = 'localhost';

  /// 本地服务器端口。
  static const int serverPort = 8199;

  /// 查询离线包更新的端点。
  static String get queryUrl => 'http://$serverHost:$serverPort/offweb';

  /// 下载包 zip 的端点。
  static String get packageUrl => 'http://$serverHost:$serverPort/package';

  /// 本地服务器的完整基础 URL。
  static String get baseUrl => 'http://$serverHost:$serverPort';
}
