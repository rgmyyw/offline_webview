[**English** | 简体中文](README.md)

---

# offline_webview

一款轻量级高性能的 Flutter 离线 Web 包 SDK。

## 特性

- **离线包管理**：下载、缓存本地 Web 资源并提供服务
- **URL 匹配**：灵活的基于规则的 URL 到 bisName 匹配
- **Flow 流程管道**：可扩展的职责链处理流程
- **WebView 集成**：无缝集成 WKWebView (iOS) / WebView (Android)
- **监控与上报**：内置日志、监控和数据上报功能

## 安装

```yaml
dependencies:
  offline_webview: ^1.0.3
```

## 快速开始

```dart
import 'package:offline_webview/offline_webview.dart';

// 配置 SDK
final params = OfflineParams()
    .config(OfflineConfigBuilder().isOpen(true).build())
    .isDebug(true)
    .logBlock((level, message) => print(message))
    .reportBlock((event, bisName, params) => print('Report: $event'))
    .monitorBlock((type, data) => print('Monitor: $type'))
    .requestServer(YourCustomRequest());

// 初始化
await OfflineWebClient.init(params);

// 在应用中使用
OfflineWebView(bisName: 'your-bis-name', url: 'https://example.com/page');
```

## 使用方法

### 配置

```dart
final config = OfflineConfigBuilder()
    .isOpen(true)                      // 开启/关闭离线功能
    .addPreDownload('bis-name-1')      // 预下载包
    .addPreDownload('bis-name-2')
    .build();
```

### 自定义请求实现

```dart
class MyRequest implements IOfflineRequest {
  @override
  void requestPackageInfo(
    String bisName,
    String version,
    RequestCallback<OfflinePackageInfo> callback,
  ) async {
    // 实现你自己的服务器查询逻辑
    final result = await fetchFromServer(bisName, version);
    callback.onSuccess(result);
  }
}
```

### URL 匹配规则

```dart
final rules = OfflineRuleConfig(
  rules: [
    OfflineRuleItem(host: 'example.com', path: '/app/*', bisName: 'my-app'),
  ],
);
```

## 架构

```
+-------------------------------------------------------------+
|                     OfflineWebClient                         |
+-------------------------------------------------------------+
                            |
                            v
+-------------------------------------------------------------+
|                    OfflineWebManager                         |
+-------------------------------------------------------------+
                            |
                            v
+-------------------------------------------------------------+
|                ResourceFlow Pipeline                         |
|  FetchPackageFlow -> DownloadFlow -> ParsePackageFlow        |
|                                    -> ReplaceResFlow         |
+-------------------------------------------------------------+
```

## 平台支持

- iOS (WKWebView)
- Android (WebView)
- Flutter Web

## 许可证

MIT License - 见 [LICENSE](LICENSE) 文件
