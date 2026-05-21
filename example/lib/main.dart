import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offline_webview/offline_webview.dart';

import 'config.dart';
import 'pages/demo_menu_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 构建带预下载的配置
  final config = OfflineConfigBuilder()
      .isOpen(true)
      .addPreDownload(AppConfig.testBisName)
      .build();

  // 构建参数
  final params = OfflineParams()
      .config(config)
      .isDebug(true)
      .logBlock((level, message) {
        debugPrint(message);
      })
      .reportBlock((event, bisName, params) {
        debugPrint('[OffWeb|Report] event=$event bisName=$bisName params=$params');
      })
      .monitorBlock((type, data) {
        debugPrint('[OffWeb|Monitor] type=$type data=$data');
      })
      .requestServer(LocalServerRequest());

  // 初始化 SDK
  await OfflineWebClient.init(params);

  runApp(const DemoApp());
}

/// 自定义的 IOfflineRequest 实现，调用 Python 服务.
class LocalServerRequest extends IOfflineRequest {
  @override
  void requestPackageInfo(
    String bisName,
    String version,
    RequestCallback<OfflinePackageInfo> callback,
  ) async {
    try {
      final url = Uri.parse(AppConfig.queryUrl).replace(
        queryParameters: {'bisName': bisName, 'offlineZipVer': version},
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final packageInfo = OfflinePackageInfo.fromJson(json);
        callback.onSuccess(packageInfo);
      } else {
        callback.onFail(
          Exception(
            'Server returned status ${response.statusCode}: ${response.body}',
          ),
        );
      }
    } catch (e) {
      callback.onFail(e);
    }
  }
}

/// 根应用组件.
class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OfflineWebView Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF212121),
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: OfflineWebViewPreWarmer(
        child: const DemoMenuPage(),
      ),
    );
  }
}