[简体中文](README_zh.md) | **English**

---

# offline_webview

A lightweight high-performance Flutter SDK for offline web package loading.

## Features

- **Offline Package Management**: Download, cache, and serve web resources locally
- **URL Matching**: Flexible rule-based URL to bisName matching
- **Flow Pipeline**: Extensible chain-of-responsibility processing pipeline
- **WebView Integration**: Seamless InAppWebView (iOS/Android) integration with preload pool
- **Performance Monitor**: Built-in debug floating panel showing loading timeline comparison
- **Monitoring & Reporting**: Built-in logging, monitoring, and data reporting
- **Fastlane CI/CD**: One-command build & distribute to Pgyer for iOS/Android

## Installation

```yaml
dependencies:
  offline_webview: ^1.1.0
```

## Quick Start

```bash
# 1. Start the Python test server (from the SDK root)
cd tool
python3 server.py
# Server auto-detects LAN IP and runs at http://<your-lan-ip>:18730
```

```dart
import 'package:offline_webview/offline_webview.dart';

// Configure the SDK
final params = OfflineParams()
    .config(OfflineConfigBuilder().isOpen(true).build())
    .isDebug(true)
    .logBlock((level, message) => print(message))
    .reportBlock((event, bisName, params) => print('Report: $event'))
    .monitorBlock((type, data) => print('Monitor: $type'))
    .requestServer(YourCustomRequest());

// Initialize
await OfflineWebClient.init(params);

// Use in your app
OfflineWebView(initialUrl: 'https://example.com/page', bisName: 'your-bis-name');
```

## Performance Monitor

The SDK includes a debug-mode performance monitor that displays a draggable floating panel showing loading timeline for each page load.

```dart
// Option 1: Wrap any page with the panel
FloatingPerformancePanel(
  child: MyPageWithWebView(),
)

// Option 2: Use standalone (OfflineWebView embeds it internally)
FloatingPerformancePanel()
```

The panel subscribes to `PerformanceMonitor.instance.timelineStream` and shows:

| Metric | Description |
|--------|-------------|
| `webViewCreatedMs` | Time from widget creation to WebView ready |
| `firstPaintMs` | Time to first visual paint |
| `loadCompleteMs` | Time to page fully loaded |
| `queryMs` | Offline query phase (offline mode only) |
| `downloadMs` | Package download phase (offline mode only) |
| `unzipMs` | Package extraction phase (offline mode only) |

Color coding: green (<50ms), blue (<200ms), yellow (<500ms), red (>=500ms).

## Local Development Server

For local testing, a Python HTTP server is provided:

```bash
cd tool
python3 server.py
```

The server auto-detects your LAN IP address so mobile devices on the same network can connect. Place offline packages in `tool/packages/`. The server automatically scans and loads package info from `.offweb.json` inside each zip.

To override the auto-detected IP, set `SERVER_HOST` in `tool/server.py`:

```python
SERVER_HOST = '192.168.1.100'  # Your fixed LAN IP
```

**Server endpoints:**
- `GET /` - Server info & registered packages
- `GET /health` - Health check
- `GET /offweb?bisName=xxx&offlineZipVer=xxx` - Query package update
- `GET /package?bisName=xxx` - Download package zip
- `GET /demo` - Demo HTML page

## Usage

### Configuration

```dart
final config = OfflineConfigBuilder()
    .isOpen(true)                      // Enable/disable offline feature
    .addPreDownload('bis-name-1')      // Pre-download packages
    .addPreDownload('bis-name-2')
    .build();
```

### Custom Request Implementation

You need to implement `IOfflineRequest` to query your server for package updates:

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

Then configure the SDK:

```dart
final params = OfflineParams()
    .config(OfflineConfigBuilder().isOpen(true).build())
    .requestServer(MyRequest());

await OfflineWebClient.init(params);
```

### URL Matching Rules

```dart
final rules = OfflineRuleConfig(
  rules: [
    OfflineRuleItem(host: 'example.com', path: '/app/*', bisName: 'my-app'),
  ],
);
```

## Architecture

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
|   ResourceFlow Pipeline   | |   PerformanceMonitor         |
|  FetchPackageFlow         | |   (singleton, Stream-based)  |
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

## CI/CD with Fastlane

The project includes Fastlane configuration for building and distributing the example app to [Pgyer](https://www.pgyer.com/).

**Prerequisites:**
- Ruby + Bundler installed
- Set `PGYER_API_KEY` environment variable

```bash
# Install dependencies
bundle install

# Build & upload iOS
bundle exec fastlane build_ios

# Build & upload Android
bundle exec fastlane build_android
```

## Platform Support

- iOS (InAppWebView / WKWebView)
- Android (InAppWebView / WebView)
- Flutter Web (limited)

## License

MIT License - see [LICENSE](LICENSE) file
