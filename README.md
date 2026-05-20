[简体中文](README_zh.md) | **English**

---

# offline_webview

A lightweight high-performance Flutter SDK for offline web package loading.

## Features

- **Offline Package Management**: Download, cache, and serve web resources locally
- **URL Matching**: Flexible rule-based URL to bisName matching
- **Flow Pipeline**: Extensible chain-of-responsibility processing pipeline
- **WebView Integration**: Seamless WKWebView (iOS) / WebView (Android) integration
- **Monitoring & Reporting**: Built-in logging, monitoring, and data reporting

## Installation

```yaml
dependencies:
  offline_webview: ^1.0.3
```

## Quick Start

```bash
# 1. Start the Python server (from the SDK root)
cd tool
python3 server.py
# Server runs at http://localhost:18730
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
OfflineWebView(bisName: 'your-bis-name', url: 'https://example.com/page');
```

## Local Development Server

For local testing, a Python HTTP server is provided:

```bash
cd tool
python3 server.py
```

Place offline packages in `tool/packages/`. The server automatically scans and loads package info from `.offweb.json` inside each zip.

**Server endpoints:**
- `GET /offweb?bisName=xxx&offlineZipVer=xxx` - Query package update
- `GET /package?bisName=xxx` - Download package zip
- `GET /demo` - Demo HTML page
- `GET /health` - Health check

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

```dart
class MyRequest implements IOfflineRequest {
  @override
  void requestPackageInfo(
    String bisName,
    String version,
    RequestCallback<OfflinePackageInfo> callback,
  ) async {
    // Implement your server query logic
    final result = await fetchFromServer(bisName, version);
    callback.onSuccess(result);
  }
}
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
                            v
+-------------------------------------------------------------+
|                ResourceFlow Pipeline                         |
|  FetchPackageFlow -> DownloadFlow -> ParsePackageFlow        |
|                                    -> ReplaceResFlow         |
+-------------------------------------------------------------+
```

## Platform Support

- iOS (WKWebView)
- Android (WebView)
- Flutter Web

## License

MIT License - see [LICENSE](LICENSE) file
