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
  offline_webview: ^1.0.0
```

## Quick Start

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
