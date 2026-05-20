# offline_webview_example

---

## English

Demo app for offline_webview package.

## Features

| Page | Description |
|------|-------------|
| Offline Loading Demo | Basic offline package loading with offweb parameter |
| Rule Matching Demo | Auto-match URLs and inject offweb parameter |
| Debug Tool | View and manage locally cached offline packages |
| Server Debug | Test if server endpoints work correctly |
| Custom URL | Custom offline package download and access URL |

## Getting Started

### 1. Install dependencies

```bash
cd example
flutter pub get
```

### 2. Run the demo

```bash
flutter run
```

### 3. Start Python server

The demo app uses a Python HTTP server for offline package management. Start it before running the app:

```bash
cd ../tool/packages
python3 server.py
```

Server port: `18730`

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── config.dart                    # Config constants (bisName, server address)
├── pages/
│   ├── home_page.dart             # Home page with all demo entries
│   ├── simple_demo_page.dart      # Simple offline loading demo
│   ├── full_demo_page.dart        # Rule matching demo
│   ├── dev_tool_page.dart         # Debug tool page
│   ├── server_debug_page.dart     # Server debug page
│   └── custom_url_config_page.dart # Custom URL demo
└── widgets/
    └── *.dart                      # Shared widgets

assets/                            # (deprecated, packages now in tool/packages/)
```

## Configuration

Modify in `lib/config.dart`:

```dart
class AppConfig {
  /// Business name, the identifier of the offline package
  static const String testBisName = 'test-offline-package';

  /// Python server port
  static const int serverPort = 18730;
}
```

## Add a New Offline Package

1. Put the offline package zip file into `tool/packages/`
2. Update `PACKAGES` and `VERSIONS` in `tool/packages/server.py`
3. Modify `testBisName` in `lib/config.dart`

## Server Endpoints

```
GET /                     - Service info
GET /health               - Health check
GET /demo                 - Demo HTML page
GET /offweb?bisName=xxx  - Query offline package update
GET /package?bisName=xxx - Download offline package zip
```

## Help

- [offline_webview documentation](../README.md)
- [Flutter documentation](https://docs.flutter.dev/)

---

## 中文

离线 Web 包的示例应用。

## 功能演示

| 页面 | 说明 |
|------|------|
| 离线加载演示 | 演示基本的离线包加载功能，URL 参数中包含 offweb 参数 |
| 规则匹配离线模式 | 通过规则自动匹配 URL 并注入 offweb 参数 |
| 调试工具 | 查看和管理本地缓存的离线包 |
| 本地服务调试 | 测试服务端点是否正常工作 |
| 自定义地址 | 自定义离线包下载地址和访问地址 |

## 开始使用

### 1. 安装依赖

```bash
cd example
flutter pub get
```

### 2. 运行示例

```bash
flutter run
```

### 3. 启动 Python 服务器

示例应用使用 Python HTTP 服务器管理离线包。在运行应用前启动：

```bash
cd ../tool/packages
python3 server.py
```

服务器端口：`18730`

## 项目结构

```
lib/
├── main.dart                      # 应用入口
├── config.dart                    # 配置常量（bisName、服务器地址等）
├── pages/
│   ├── home_page.dart             # 主页，展示所有演示入口
│   ├── simple_demo_page.dart      # 简单离线加载演示
│   ├── full_demo_page.dart        # 规则匹配演示
│   ├── dev_tool_page.dart         # 调试工具页面
│   ├── server_debug_page.dart     # 服务调试页面
│   └── custom_url_config_page.dart # 自定义地址演示
└── widgets/
    └── *.dart                      # 共用组件

assets/                            # (已废弃，离线包移至 tool/packages/)
```

## 配置说明

在 `lib/config.dart` 中修改配置：

```dart
class AppConfig {
  /// 业务名称，对应离线包的标识
  static const String testBisName = 'test-offline-package';

  /// Python 服务器端口
  static const int serverPort = 18730;
}
```

## 添加新的离线包

1. 将离线包 zip 文件放入 `tool/packages/` 目录
2. 更新 `PACKAGES` 和 `VERSIONS` 配置
3. 修改 `lib/config.dart` 中的 `testBisName`

## 服务器端点

```
GET /                     - 服务信息
GET /health               - 健康检查
GET /demo                 - 演示页面
GET /offweb?bisName=xxx  - 查询离线包更新
GET /package?bisName=xxx - 下载离线包 zip
```

## 获取帮助

- [offline_webview 主文档](../README.md)
- [Flutter 官方文档](https://docs.flutter.dev/)
