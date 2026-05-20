import 'package:flutter/foundation.dart';

import '../core/offline_const.dart';

/// 离线Web SDK统一日志工具。
///
/// 格式: `[OffWeb|Tag] message`
///
/// 使用方式:
/// ```dart
/// Logger.d('Manager', '初始化完成');
/// Logger.e('Download', '下载失败: $e');
/// ```
class Logger {
  Logger._();

  static const String _prefix = 'OffWeb';

  static OfflineWebLogBlock? _logBlock;

  /// 初始化日志回调，由[OfflineWebManager]在init时调用。
  static void init(OfflineWebLogBlock? logBlock) {
    _logBlock = logBlock;
  }

  static void d(String tag, String message) {
    _log(OfflineWebLogLevel.debug, tag, message);
  }

  static void i(String tag, String message) {
    _log(OfflineWebLogLevel.info, tag, message);
  }

  static void w(String tag, String message) {
    _log(OfflineWebLogLevel.warning, tag, message);
  }

  static void e(String tag, String message) {
    _log(OfflineWebLogLevel.error, tag, message);
  }

  static void _log(OfflineWebLogLevel level, String tag, String message) {
    final formatted = '[$_prefix|$tag] $message';
    if (_logBlock != null) {
      _logBlock!.call(level, formatted);
    } else {
      debugPrint(formatted);
    }
  }
}
