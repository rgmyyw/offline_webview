import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

import 'param_offline_demo_page.dart';
import 'rule_match_offline_demo_page.dart';
import 'dev_tool_page.dart';
import 'server_debug_page.dart';
import 'offline_config_page.dart';

class DemoMenuPage extends StatelessWidget {
  const DemoMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = <Map<String, dynamic>>[
      {
        'title': '离线加载模式',
        'subtitle': 'URL带offweb参数，直接加载离线包',
        'page': const ParamOfflineDemoPage(),
      },
      {
        'title': '规则匹配模式',
        'subtitle': '自动匹配URL并注入offweb参数',
        'page': const RuleMatchOfflineDemoPage(),
      },
      {
        'title': '调试工具',
        'subtitle': '离线包管理、URL匹配、缓存清理等',
        'page': const DevToolPage(),
      },
      {
        'title': '服务调试',
        'subtitle': '测试本地服务端点是否正常工作',
        'page': const ServerDebugPage(),
      },
      {
        'title': '自定义配置',
        'subtitle': '自定义离线包下载地址和访问地址',
        'page': const OfflineConfigPage(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('OfflineWebView Demo'),
      ),
      body: ListView.builder(
        itemCount: demos.length,
        itemBuilder: (context, index) {
          final demo = demos[index];
          final page = demo['page'] as Widget;

          return ListTile(
            title: Text(demo['title'] as String),
            subtitle: Text(demo['subtitle'] as String),
            trailing: Icon(
              Icons.chevron_right,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
            },
          );
        },
      ),
    );
  }
}