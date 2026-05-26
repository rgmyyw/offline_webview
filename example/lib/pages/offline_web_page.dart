import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';
import 'package:offline_webview_example/config.dart';

import '../l10n/app_localizations.dart';

class OfflineWebPage extends StatelessWidget {
  final String visitUrl;

  const OfflineWebPage({super.key, required this.visitUrl});

  @override
  Widget build(BuildContext context) => _OfflineWebPage(visitUrl: visitUrl);
}

class _OfflineWebPage extends StatefulWidget {
  final String visitUrl;

  const _OfflineWebPage({required this.visitUrl});

  @override
  State<_OfflineWebPage> createState() => _OfflineWebPageState();
}

class _OfflineWebPageState extends State<_OfflineWebPage> {
  final _controller = OfflineWebViewController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.offlinePackageMode),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reloadOfflineWeb();
            },
          ),
        ],
      ),
      body: OfflineWebView(
        initialUrl: widget.visitUrl,
        controller: _controller,
        enableVConsole: AppConfig.enableVConsole,
      ),
    );
  }
}