# Changelog

## [1.1.0] - 2025-05-22

- Feat: PerformanceMonitor 单例 + LoadingTimeline 数据模型
- Feat: FloatingPerformancePanel 可拖动悬浮面板，实时展示加载耗时
- Feat: Fastlane + Pgyer 一键构建分发 (iOS/Android)
- Feat: 测试服务器自动检测局域网 IP，支持跨设备访问
- Feat: Example 添加 Android INTERNET 权限和 iOS 本地网络使用说明
- Feat: Example 添加 Flutter 国际化支持 (en/zh)
- Fix: force_update_page initState 中 BuildContext 时序问题
- Fix: LocalServer 日志格式添加 http:// 前缀
- Chore: 切换 pub 源至 pub.dev

## [1.0.4] - 2025-05-20

- Docs: add Python server setup, endpoints, and IOfflineRequest implementation example

## [1.0.3] - 2025-05-20

- Fix: shorten pubspec description and fix doc comment for pub.dev score

## [1.0.2] - 2025-05-20

- Refactor: unify to Python server, remove Dart local_server
- Python server auto-scans packages/ directory and reads version from .offweb.json
- Update port from 8199 to 18730

## [1.0.1] - 2024-05-20

- Improved pub.dev score with English description and README
- Fixed lint warnings (prefer_final_fields)
- Updated analysis_options.yaml

## [1.0.0] - 2024-05-20

- Initial release
- Offline package download and caching
- URL to bisName matching
- Flow-based resource processing pipeline
- WebView integration for iOS and Android
- Built-in monitoring and reporting callbacks
- Custom request implementation support
