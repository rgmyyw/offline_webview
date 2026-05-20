import 'package:flutter/material.dart';

import 'simple_demo_page.dart';
import 'full_demo_page.dart';
import 'dev_tool_page.dart';
import 'server_debug_page.dart';
import 'custom_url_config_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = <Map<String, dynamic>>[
      {
        'title': '离线加载',
        'subtitle': 'URL中包含offweb参数,直接加载离线包',
        'page': const SimpleDemoPage(),
      },
      {
        'title': '规则匹配离线模式-待完善',
        'subtitle': '通过规则自动匹配URL并注入offweb参数',
        'page': const FullDemoPage(),
      },
      {
        'title': '调试工具',
        'subtitle': '查看和管理本地缓存的离线包',
        'page': const DevToolPage(),
      },
      {
        'title': '本地服务调试',
        'subtitle': '测试服务端点是否正常工作',
        'page': const ServerDebugPage(),
      },
      {
        'title': '自定义地址',
        'subtitle': '自定义离线包下载地址和访问地址',
        'page': const CustomUrlConfigPage(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('OfflineWebView Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: demos.length,
        itemBuilder: (context, index) {
          final demo = demos[index];
          return ListTile(
            title: Text(demo['title'] as String),
            subtitle: Text(demo['subtitle'] as String),
            trailing: const Icon(
              Icons.chevron_right,
              size: 24,
              color: Colors.blue,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => demo['page'] as Widget),
              );
            },
          );
        },
      ),
    );
  }
}
