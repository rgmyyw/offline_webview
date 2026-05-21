import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

class OfflineWebPage extends StatelessWidget {
  final String visitUrl;

  const OfflineWebPage({
    super.key,
    required this.visitUrl,
  });

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
  String _status = '加载中...';
  final _controller = OfflineWebViewController();
  DateTime? _startTime;
  late bool _isLocalLoading = LocalServer.isLocalServerUrl(
    OfflineWebView.resolveOfflineUrlSync(widget.visitUrl),
  );

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _status = '正在加载: ${widget.visitUrl}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('离线包模式'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _startTime = DateTime.now();
              _controller.reloadOfflineWeb();
            },
          ),
        ],
      ),
      body: OfflineWebView(
        initialUrl: widget.visitUrl,
        controller: _controller,
        onLoadStart: (controller, url) {
          setState(() {
            _status = '加载中: ${url?.toString() ?? ""}';
            _startTime = DateTime.now();
          });
        },
        onLoadStop: (controller, url) {
          final elapsed = DateTime.now()
              .difference(_startTime!)
              .inMilliseconds;
          setState(() {
            _status = '加载完成: ${url?.toString() ?? ""}';
            _isLocalLoading =
                url != null && LocalServer.isLocalServerUrl(url.toString());
            Logger.i('OfflineWebPage', '加载完成 (耗时: ${elapsed}ms)');
          });
        },
        onReceivedError: (controller, error) {
          setState(() {
            _status = '加载错误: ${error?.description ?? "unknown"}';
          });
        },
      ),
    );
  }
}