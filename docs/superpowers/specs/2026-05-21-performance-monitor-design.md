# Performance Monitor Design

## Overview

SDK 内部性能监控模块，在 Debug 模式下以可拖动悬浮面板形式展示离线加载与网络加载的各阶段耗时对比。

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  PerformanceMonitor                       │
│                  (Singleton, lib/src/monitor/)            │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ data: _LoadingTimeline                               │ │
│  │ controller: StreamController<LoadingTimeline>        │ │
│  └─────────────────────────────────────────────────────┘ │
│                         ▲                                 │
│                         │ records各阶段                   │
│  ┌──────────────────────┼──────────────────────────────┐ │
│  │ OfflineWebView       │ OfflineFlow                   │ │
│  │ - WebViewCreated      │ - Query                       │ │
│  │ - LoadStart           │ - Download                    │ │
│  │ - FirstPaint          │ - Unzip                      │ │
│  │ - LoadComplete        │                               │ │
│  └───────────────────────┴──────────────────────────────┘ │
│                         │ streams                        │
│                         ▼                                 │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ FloatingPerformancePanel (Overlay)                   │ │
│  │ - 订阅 timelineStream                                │ │
│  │ - 展示离线 vs 网络加载耗时对比                        │ │
│  │ - 可拖动，关闭按钮                                    │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Data Model

### LoadingTimeline

```dart
class LoadingTimeline {
  final LoadingMode mode;
  final int totalMs;
  final int? queryMs;
  final int? downloadMs;
  final int? unzipMs;
  final int webViewCreatedMs;
  final int firstPaintMs;
  final int loadCompleteMs;
}
```

### LoadingMode

```dart
enum LoadingMode { offline, network }
```

## Components

| Component | File | Responsibility |
|-----------|------|----------------|
| PerformanceMonitor | performance_monitor.dart | Singleton, data collection & stream |
| LoadingTimeline | loading_timeline.dart | Data model |
| FloatingPerformancePanel | floating_performance_panel.dart | Draggable overlay panel |
| PerformanceMonitorWidget | performance_monitor_widget.dart | Injected into widget tree |

## Panel UI

- **Position**: Top-right corner (offset: 16px from right, 60px from top)
- **Size**: Compact card ~240x180
- **Draggable**: Yes, via GestureDetector + Overlay
- **Closeable**: Yes, X button to hide
- **Data Display**: Side-by-side comparison of offline vs network timing

## Integration

1. `OfflineWebView` calls `PerformanceMonitor.instance.recordXxx()` at each stage
2. `OfflineFlow` (FetchPackageFlow) calls `recordOfflinePhase()` for query/download/unzip
3. `FloatingPerformancePanel` subscribes to `timelineStream` and rebuilds on each emission