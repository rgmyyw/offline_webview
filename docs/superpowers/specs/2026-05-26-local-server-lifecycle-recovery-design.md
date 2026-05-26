# LocalServer 后台恢复自动重启设计

## 问题

iOS app 长时间挂后台后，系统会回收 `HttpServer` 绑定的 socket 端口。App 恢复前台时，
`LocalServer` 内存中的 `_servers` Map 仍持有失效的引用，导致 WebView 加载 `http://localhost:死端口/` 白屏。

## 方案

OfflineWebManager 监听 Flutter 生命周期，在 `resumed` 时触发 LocalServer 健康检查，
对每个端口发 HEAD 请求，死掉的服务器自动重启并保持原端口不变。

## 改动文件

### 1. `lib/src/server/local_server.dart`

新增方法：

**`healthCheckAll()`**
- 遍历 `_servers`，对每个 bisName 的 `http://localhost:port/` 发 HEAD 请求
- HttpClient 设置 `connectionTimeout: Duration(milliseconds: 500)`
- 成功 → 跳过
- 失败 → 调用 `_restartServer(bisName)`
- 全部完成后日志汇总

**`_restartServer(String bisName)`**
- 从 `_servers` 移除旧引用，调用 `server.close(force: true)`
- 等待 ~100ms 让 OS 释放端口
- 尝试 `HttpServer.bind(InternetAddress.loopbackIPv4, oldPort)`，最多重试 3 次，间隔 100ms
- 成功 → 更新 `_servers[bisName]` 和 `_ports[bisName]`，恢复 listening
- 全部失败 → 从 `_servers` 和 `_ports` 中移除该条目，日志告警
- **不回退到 port 0**——端口必须保持原值

### 2. `lib/src/core/offline_web_manager.dart`

- 混入 `WidgetsBindingObserver`
- `init()` 末尾注册观察者：`WidgetsBinding.instance.addObserver(this)`
- `clean()` 中移除观察者：`WidgetsBinding.instance.removeObserver(this)`
- 新增 import：`package:flutter/widgets.dart`

**`didChangeAppLifecycleState(AppLifecycleState state)`**
- 仅在 `state == AppLifecycleState.resumed` 时触发
- 调用 `LocalServer.instance.healthCheckAll()`

## 触发时机

- `paused → resumed`：从后台回到前台 → 触发
- `inactive → resumed`：短暂中断（如通知中心）→ 不触发

## 不做的事

- 不主动刷新已打开的 WebView 页面（端口不变，页面无需刷新）
- 不在 `init()` 之外的时机启动新服务器
- 不回退到随机端口（端口必须保持不变）

## 边界情况

| 场景 | 处理 |
|------|------|
| 所有服务器存活 | 无操作，日志记录 |
| 部分服务器死亡 | 仅重启死亡的服务器 |
| 重启时原端口被占用 | 重试 3 次后放弃，移除该条目，日志告警 |
| 无服务器运行 | 跳过，无操作 |
