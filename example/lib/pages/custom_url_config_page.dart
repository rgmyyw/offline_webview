import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offline_webview/offline_webview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../config.dart';
import 'custom_url_web_page.dart';

/// 配置页面：输入服务器 URL、bisName 和访问 URL，
/// 然后选择是否使用离线包加载。
class CustomUrlConfigPage extends StatefulWidget {
  const CustomUrlConfigPage({super.key});

  @override
  State<CustomUrlConfigPage> createState() => _CustomUrlConfigPageState();
}

class _CustomUrlConfigPageState extends State<CustomUrlConfigPage> {
  final _serverUrlController = TextEditingController(
    text: AppConfig.baseUrl,
  );
  final _visitUrlController = TextEditingController(
    text: 'https://www.baidu.com?offweb=academy',
  );
  final _bisNameController = TextEditingController(text: 'academy');

  bool _isLoading = false;
  bool _isFetchingPackages = false;
  List<String> _availablePackages = [];
  String? _selectedPackage;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _visitUrlController.dispose();
    _bisNameController.dispose();
    super.dispose();
  }

  Future<void> _directNavigate() {
    final visitUrl = _visitUrlController.text.trim();
    final bisName = _bisNameController.text.trim();

    if (visitUrl.isEmpty || bisName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写访问地址和 bisName')));
      return Future.value();
    }

    // OfflineWebClient.setRequest(_LocalServerRequest());

    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomUrlWebPage(visitUrl: visitUrl, useOffline: true),
      ),
    );
  }

  Future<void> _fetchPackages() async {
    final serverUrl = _serverUrlController.text.trim();
    if (serverUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先填写服务器地址')));
      return;
    }

    setState(() => _isFetchingPackages = true);

    try {
      final uri = Uri.parse(serverUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final packages =
            (json['packages'] as List<dynamic>?)?.cast<String>() ?? [];

        if (!mounted) return;
        setState(() {
          _availablePackages = packages;
        });

        if (packages.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未获取到可用离线包')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '获取到 ${packages.length} 个离线包: ${packages.join(", ")}',
              ),
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('请求失败: ${response.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('获取离线包失败: $e')));
    } finally {
      if (mounted) {
        setState(() => _isFetchingPackages = false);
      }
    }
  }

  void _onPackageSelected(String? package) {
    if (package == null) return;
    setState(() {
      _selectedPackage = package;
      _bisNameController.text = package;
      // 自动更新访问地址
      final baseUrl = _visitUrlController.text.split('?').first;
      _visitUrlController.text = '$baseUrl?offweb=$package';
    });
  }

  Future<void> _startLoading({required bool useOffline}) async {
    final serverUrl = _serverUrlController.text.trim();
    final visitUrl = _visitUrlController.text.trim();
    final bisName = _bisNameController.text.trim();

    if (serverUrl.isEmpty || visitUrl.isEmpty || bisName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写所有字段')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (useOffline) {
        OfflineWebClient.setRequest(_LocalServerRequest());
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CustomUrlWebPage(visitUrl: visitUrl, useOffline: useOffline),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Logger.e('CustomURL', '$e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('初始化失败: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义地址配置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _serverUrlController,
              label: '离线包服务地址',
              hint: '例: http://192.168.1.100:9999',
              icon: Icons.cloud_download,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isFetchingPackages ? null : _fetchPackages,
                icon: _isFetchingPackages
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('获取离线包列表'),
              ),
            ),
            if (_availablePackages.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedPackage,
                decoration: InputDecoration(
                  labelText: '选择离线包',
                  prefixIcon: const Icon(Icons.inventory_2, size: 20),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                hint: const Text('请选择离线包'),
                items: _availablePackages
                    .map(
                      (pkg) => DropdownMenuItem(value: pkg, child: Text(pkg)),
                    )
                    .toList(),
                onChanged: _onPackageSelected,
              ),
            ],
            const SizedBox(height: 12),
            _buildTextField(
              controller: _bisNameController,
              label: '业务名称 (bisName)',
              hint: '例: package',
              icon: Icons.inventory_2,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _visitUrlController,
              label: '访问地址',
              hint: '例: https://example.com?offweb=package',
              icon: Icons.language,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _startLoading(useOffline: true),
                icon: _loadingIcon(),
                label: const Text('使用离线包加载'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _startLoading(useOffline: false),
                icon: const Icon(Icons.language),
                label: const Text('不使用离线包(对照组)'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _directNavigate,
                icon: const Icon(Icons.open_in_new),
                label: const Text('直接跳转(不预加载)'),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _viewScreenshot(context),
                  icon: const Icon(Icons.image),
                  label: const Text('查看截图缓存'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _cleanOfflinePackage,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('清理离线包'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cleanOfflinePackage() async {
    final bisName = _bisNameController.text.trim();
    if (bisName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先填写 bisName')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清理'),
        content: Text('确定要清理 "$bisName" 的离线包缓存吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await OfflineWebManager.instance.cleanBisName(bisName);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已清理 "$bisName" 离线包缓存')));
  }

  Future<void> _viewScreenshot(BuildContext context) async {
    final bisName = _bisNameController.text.trim();
    if (bisName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写 bisName')),
      );
      return;
    }
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final appDir = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(appDir.path, 'offline_web', bisName, 'cur', 'screenshot.png'),
    );
    if (!file.existsSync()) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('截图不存在: ${file.path}')),
      );
      return;
    }
    final bytes = file.readAsBytesSync();
    if (!mounted) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => _ScreenshotViewer(bytes: bytes, path: file.path),
      ),
    );
  }

  Widget? _loadingIcon() {
    if (!_isLoading) return const Icon(Icons.play_arrow);
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }
}

class _LocalServerRequest extends IOfflineRequest {
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

class _ScreenshotViewer extends StatelessWidget {
  final Uint8List bytes;
  final String path;

  const _ScreenshotViewer({required this.bytes, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('截图查看'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '大小: ${bytes.length} 字节\n路径: $path',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Center(
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (_, error, __) => Text('图片加载失败: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
