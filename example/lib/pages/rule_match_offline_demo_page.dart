import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

import '../l10n/app_localizations.dart';

import '../config.dart';

/// 完整演示页面：演示基于规则的 URL 匹配.
///
/// URL 中不包含 `offweb` 参数。而是通过 [OfflineRuleConfig]
/// 设置按 host/path 模式匹配 URL 并自动注入 `offweb` 参数.
class RuleMatchOfflineDemoPage extends StatelessWidget {
  const RuleMatchOfflineDemoPage({super.key});

  /// 原始 URL，不包含 offweb 参数.
  /// 规则引擎将匹配 host 并注入 offweb 参数.
  String get _originalUrl =>
      'http://${AppConfig.serverHost}:${AppConfig.serverPort}/demo';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ruleMatchDemo),
      ),
      body: FloatingPerformancePanel(
        child: OfflineWebView(
          initialUrl: _originalUrl,
          enableVConsole: AppConfig.enableVConsole,
        ),
      ),
    );
  }
}