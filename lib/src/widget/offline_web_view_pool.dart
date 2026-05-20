import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../util/off_web_log.dart';

/// WebView 进程预热组件。
///
/// 在 App 根布局中嵌入此组件，提前创建一个常驻隐藏 WebView，
/// 使 WKWebView/WebView 的底层进程提前初始化。
class OfflineWebViewPreWarmer extends StatefulWidget {
  final Widget child;

  const OfflineWebViewPreWarmer({super.key, required this.child});

  @override
  State<OfflineWebViewPreWarmer> createState() =>
      _OfflineWebViewPreWarmerState();
}

class _OfflineWebViewPreWarmerState extends State<OfflineWebViewPreWarmer> {
  bool _warmed = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: -10000,
          top: -10000,
          child: SizedBox(
            width: 1,
            height: 1,
            child: _warmed
                ? InAppWebView(
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                    ),
                    onWebViewCreated: (_) {
                      Logger.d('PreWarmer', 'WebView 已创建 (WebKit进程预热完成)');
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    Logger.d('PreWarmer', 'initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Logger.d('PreWarmer', 'postFrameCallback, 即将创建预热WebView');
      if (mounted) setState(() => _warmed = true);
    });
  }
}
