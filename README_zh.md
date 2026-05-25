[**English** | 简体中文](README.md)

---

# offline_webview

一款轻量级高性能的 Flutter 离线 Web 包 SDK。

## 特性

- **离线包管理**：下载、缓存本地 Web 资源并提供服务
- **URL 匹配**：灵活的基于规则的 URL 到 bisName 匹配
- **Flow 流程管道**：可扩展的职责链处理流程
- **WebView 集成**：无缝集成 InAppWebView (iOS/Android)，支持预加载池
- **性能监控**：内置 Debug 模式悬浮面板，实时展示加载各阶段耗时
- **监控与上报**：内置日志、监控和数据上报功能
- **Fastlane CI/CD**：一条命令构建并分发到蒲公英 (iOS/Android)

## 安装

```yaml
dependencies:
  offline_webview: ^1.1.0
```

## 快速开始

```bash
# 1. 启动 Python 测试服务器（在 SDK 根目录）
cd tool
python3 server.py
# 服务器自动检测局域网 IP，运行在 http://<局域网IP>:18730
```

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
OfflineWebView(initialUrl: 'https://example.com/page', bisName: 'your-bis-name');
```

## 性能监控

SDK 内置了 Debug 模式下的性能监控模块，以可拖动悬浮面板形式实时展示每次页面加载的各阶段耗时。

```dart
// 方式一：包裹任意页面
FloatingPerformancePanel(
  child: MyPageWithWebView(),
)

// 方式二：单独使用（OfflineWebView 内部已嵌入）
FloatingPerformancePanel()
```

面板订阅 `PerformanceMonitor.instance.timelineStream`，展示以下指标：

| 指标 | 说明 |
|------|------|
| `webViewCreatedMs` | 从组件创建到 WebView 就绪的耗时 |
| `firstPaintMs` | 首帧可见耗时 |
| `loadCompleteMs` | 页面完全加载耗时 |
| `queryMs` | 离线查询阶段（仅离线模式） |
| `downloadMs` | 包下载阶段（仅离线模式） |
| `unzipMs` | 包解压阶段（仅离线模式） |

颜色分级：绿色 (<50ms)、蓝色 (<200ms)、黄色 (<500ms)、红色 (>=500ms)。

## 本地开发服务器

本地测试提供了 Python HTTP 服务器：

```bash
cd tool
python3 server.py
```

服务器自动检测本机局域网 IP，同一网络下的移动设备可直接访问。将离线包放在 `tool/packages/` 目录下，服务器会自动扫描并从 zip 包内的 `.offweb.json` 读取包信息。

如需固定 IP，修改 `tool/server.py` 中的 `SERVER_HOST`：

```python
SERVER_HOST = '192.168.1.100'  # 你的固定局域网 IP
```

**服务器端点：**
- `GET /` - 服务信息与已注册离线包
- `GET /health` - 健康检查
- `GET /offweb?bisName=xxx&offlineZipVer=xxx` - 查询离线包更新
- `GET /package?bisName=xxx` - 下载离线包 zip
- `GET /demo` - 演示 HTML 页面

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

需要实现 `IOfflineRequest` 来查询服务器的离线包更新：

```dart
class MyRequest implements IOfflineRequest {
  @override
  void requestPackageInfo(
    String bisName,
    String version,
    RequestCallback<OfflinePackageInfo> callback,
  ) async {
    final url = Uri.parse('http://your-server:18730/offweb').replace(
      queryParameters: {'bisName': bisName, 'offlineZipVer': version},
    );
    final response = await http.get(url);
    final json = jsonDecode(response.body);
    callback.onSuccess(OfflinePackageInfo.fromJson(json));
  }
}
```

然后配置 SDK：

```dart
final params = OfflineParams()
    .config(OfflineConfigBuilder().isOpen(true).build())
    .requestServer(MyRequest());

await OfflineWebClient.init(params);
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
              +-------------+-------------+
              |                           |
              v                           v
+---------------------------+ +-----------------------------+
|   ResourceFlow 流程管道   | |   PerformanceMonitor         |
|  FetchPackageFlow         | |   (单例, 基于 Stream)        |
|    -> DownloadFlow        | |   ↳ FloatingPerformancePanel |
|    -> ParsePackageFlow    | +-----------------------------+
|    -> ReplaceResFlow      |
+---------------------------+
              |
              v
+-------------------------------------------------------------+
|                   OfflineWebView                             |
|   (InAppWebView + LocalServer + WebViewPreloadPool)          |
+-------------------------------------------------------------+
```

## Fastlane CI/CD

项目内置了 Fastlane 配置，支持一键构建并分发 Example 应用到 [蒲公英](https://www.pgyer.com/)。

**前置条件：**
- 安装 Ruby + Bundler
- 设置 `PGYER_API_KEY` 环境变量

```bash
# 安装依赖
bundle install

# 构建 iOS 并上传
bundle exec fastlane build_ios

# 构建 Android 并上传
bundle exec fastlane build_android
```

## 平台支持

- iOS (InAppWebView / WKWebView)
- Android (InAppWebView / WebView)
- Flutter Web (有限支持)

## 许可证

MIT License - 见 [LICENSE](LICENSE) 文件
