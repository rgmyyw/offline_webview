[**English**](https://github.com/rgmyyw/offline_webview/blob/main/README.md) | 简体中文

---

# offline_webview

一款轻量级高性能的 Flutter 离线 Web 包 SDK。

## 特性

- **离线包管理**：下载、缓存本地 Web 资源并通过 localhost HTTP 服务加载
- **URL 匹配**：灵活的基于规则的 URL 到 bisName 匹配（参数模式 & 规则模式）
- **Flow 流程管道**：可扩展的职责链处理流程
- **WebView 集成**：无缝集成 InAppWebView (iOS/Android)，支持截图缓存和 vConsole 调试面板
- **性能监控**：内置 Debug 模式悬浮面板，实时展示加载各阶段耗时
- **监控与上报**：内置日志、监控和数据上报功能
- **本地服务器**：每个离线包独立端口，通过 localhost HTTP 提供资源，无需 file:// 协议
- **Fastlane CI/CD**：一条命令构建并分发到蒲公英 (iOS/Android)

## 安装

```yaml
dependencies:
  offline_webview: ^1.1.0
```

## 快速开始

### 1. 启动测试服务器

```bash
cd tool
python3 server.py
# 服务器自动检测局域网 IP，运行在 http://<局域网IP>:18730
```

### 2. 初始化 SDK

```dart
import 'package:offline_webview/offline_webview.dart';

// 构建配置（preDownloadAll 下载服务器上所有可用离线包）
final config = OfflineConfigBuilder()
    .isOpen(true)
    .preDownloadAll(true)
    .build();

// 构建参数
final params = OfflineParams()
    .config(config)
    .isDebug(true)
    .logBlock((level, message) => print(message))
    .reportBlock((event, bisName, params) => print('Report: $event'))
    .monitorBlock((type, data) => print('Monitor: $type'))
    .requestServer(YourRequest());

await OfflineWebClient.init(params);
```

### 3. 使用 OfflineWebView

```dart
// 参数模式：URL 中包含 ?offweb=bisName
OfflineWebView(
  initialUrl: 'https://example.com/page?offweb=my-bis-name',
  enableVConsole: true,  // 注入 vConsole 调试面板
)

// 使用 controller 进行刷新
final controller = OfflineWebViewController();
OfflineWebView(
  initialUrl: 'https://example.com/page?offweb=my-bis-name',
  controller: controller,
  onLoadTiming: (totalMs) => print('加载耗时 ${totalMs}ms'),
)

// 刷新离线页面
controller.reloadOfflineWeb();
```

### 4. 实现 IOfflineRequest

```dart
class YourRequest extends IOfflineRequest {
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

  @override
  void requestAllBisNames(RequestCallback<List<String>> callback) async {
    final response = await http.get(Uri.parse('http://your-server:18730'));
    final json = jsonDecode(response.body);
    final packages = (json['packages'] as List).map((e) => e.toString()).toList();
    callback.onSuccess(packages);
  }
}
```

## 制作离线包

离线包是一个标准的 `.zip` 文件，包含 Web 资源和一个版本清单文件。

### 包结构

```
my-package.zip
├── .offweb.json      # 必需：版本清单
├── index.html        # 入口页面
├── css/
│   └── style.css
├── js/
│   └── app.js
└── images/
    └── logo.png
```

### 版本清单（`.offweb.json`）

将此文件放在 zip 包的根目录：

```json
{
  "bisName": "my-package",
  "version": "v1"
}
```

### 要求

- **`.offweb.json`** 必须存在于 zip 根目录，包含 `bisName` 和 `version` 字段
- **`index.html`** 必须存在作为入口页面
- 所有资源路径（CSS、JS、图片）使用**相对路径**
- H5 页面需支持 null-origin 的 cookie/storage（从 `localhost` 加载）

### 上传到服务器

将 zip 文件放到服务器的 `packages/` 目录，或使用内置的上传页面 `http://<服务器IP>:18730/upload`。

### 服务器查询 API

SDK 查询服务器时，响应格式为：

```json
{
  "bisName": "my-package",
  "result": 1,
  "url": "http://server:18730/package?bisName=my-package",
  "refreshMode": 0,
  "version": "v2"
}
```

| 字段 | 说明 |
|------|------|
| `result` | `-1` = 已禁用，`0` = 版本一致，`1` = 有更新 |
| `url` | zip 包下载地址 |
| `refreshMode` | `0` = 普通，`1` = 强制刷新 |
| `version` | 最新版本号 |

## URL 匹配

### 参数模式

在 URL 中追加 `?offweb=<bisName>`，SDK 自动拦截：

```dart
OfflineWebView(
  initialUrl: 'https://example.com/page?offweb=my-bis-name',
)
```

### 规则模式

通过 `OfflineRuleConfig` 配置 host/path 模式匹配，无需修改 URL：

```dart
final params = OfflineParams()
    .config(OfflineConfigBuilder().isOpen(true).build())
    .setRule(OfflineRuleConfig(
      rules: [
        OfflineRuleItem(host: 'example.com', path: '/app/*', bisName: 'my-app'),
      ],
    ))
    .requestServer(YourRequest());
```

## 性能监控

SDK 内置了 Debug 模式下的性能监控模块，以可拖动悬浮面板形式实时展示每次页面加载的各阶段耗时：

```dart
FloatingPerformancePanel(
  child: OfflineWebView(initialUrl: '...'),
)

// 或单独使用（OfflineWebView 内部已嵌入）
FloatingPerformancePanel()
```

| 指标 | 说明 |
|------|------|
| `webViewCreatedMs` | 从组件创建到 WebView 就绪的耗时 |
| `firstPaintMs` | 首帧可见耗时 |
| `loadCompleteMs` | 页面完全加载耗时 |
| `queryMs` | 离线查询阶段（仅离线模式） |
| `downloadMs` | 包下载阶段（仅离线模式） |
| `unzipMs` | 包解压阶段（仅离线模式） |

颜色分级：绿色 (<50ms)、蓝色 (<200ms)、黄色 (<500ms)、红色 (>=500ms)。

## 配置

```dart
final config = OfflineConfigBuilder()
    .isOpen(true)                      // 开启/关闭离线功能
    .preDownloadAll(true)              // 预下载服务器上所有可用包
    .addPreDownload('bis-name-1')      // 预下载指定包
    .addPreDownload('bis-name-2')
    .addDisable('bis-name-3')          // 禁用指定包
    .build();
```

## 本地开发服务器

本地测试提供了 Python HTTP 服务器：

```bash
cd tool
python3 server.py
```

**服务器端点：**
- `GET /` - 服务信息与已注册离线包
- `GET /health` - 健康检查
- `GET /offweb?bisName=xxx&offlineZipVer=xxx` - 查询离线包更新
- `GET /package?bisName=xxx` - 下载离线包 zip
- `GET /upload` - 上传页面
- `POST /upload` - 上传 zip 包
- `GET /demo` - 演示 HTML 页面

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

```bash
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
