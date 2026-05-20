# offline_webview_example

离线 Web 包的示例应用。

## 功能演示

本示例应用包含以下功能演示：

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

### 3. 启动本地服务器（可选）

示例应用内置了一个本地 HTTP 服务器用于测试。在运行应用后会自动启动。

本地服务器端口：`8199`

## 项目结构

```
lib/
├── main.dart                      # 应用入口，启动本地服务器
├── config.dart                    # 配置常量（bisName、服务器地址等）
├── local_server.dart              # 本地测试服务器实现
├── pages/
│   ├── home_page.dart             # 主页，展示所有演示入口
│   ├── simple_demo_page.dart      # 简单离线加载演示
│   ├── full_demo_page.dart        # 规则匹配演示
│   ├── dev_tool_page.dart         # 调试工具页面
│   ├── server_debug_page.dart      # 服务调试页面
│   └── custom_url_config_page.dart # 自定义地址演示
└── widgets/
    └── *.dart                      # 共用组件

assets/
├── packages.json                  # 离线包元数据配置
└── offline-packages/              # 离线包 zip 文件存放目录
```

## 配置说明

在 `lib/config.dart` 中修改配置：

```dart
class AppConfig {
  /// 业务名称，对应离线包的标识
  static const String testBisName = 'test-offline-package';

  /// 本地服务器端口
  static const int serverPort = 8199;
}
```

## 添加新的离线包

1. 将离线包 zip 文件放入 `assets/offline-packages/` 目录
2. 更新 `assets/packages.json` 配置包信息
3. 修改 `lib/config.dart` 中的 `testBisName`

## packages.json 配置格式

```json
[
  {
    "bisName": "test-offline-package",
    "version": "1.0.0",
    "packageUrl": "http://localhost:8199/package?bisName=test-offline-package"
  }
]
```

## 获取帮助

- [offline_webview 主文档](../README.md)
- [Flutter 官方文档](https://docs.flutter.dev/)