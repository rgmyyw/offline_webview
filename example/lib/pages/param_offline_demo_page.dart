import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

import '../l10n/app_localizations.dart';

import '../config.dart';

/// 简单演示页面：URL 包含 ?offweb=test-offline-package.
///
/// OfflineWebView 组件会自动拦截此 URL，
/// 如果离线包可用则加载离线包。
class ParamOfflineDemoPage extends StatelessWidget {
  const ParamOfflineDemoPage({super.key});

  String _buildUrl() {
    return '${AppConfig.baseUrl}/demo?offweb=${AppConfig.testBisName}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.offlineLoadingMode),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 刷新由 OfflineWebView 内部处理
            },
          ),
        ],
      ),
      body: FloatingPerformancePanel(
        child: OfflineWebView(
          initialUrl: _buildUrl(),
        ),
      ),
    );
  }
}