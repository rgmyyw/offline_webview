import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offline_webview/offline_webview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_localizations.dart';

import '../config.dart';
import 'offline_web_page.dart';
import 'online_web_page.dart';

/// 配置页面：输入服务器 URL、bisName 和访问 URL，
/// 然后选择是否使用离线包加载。
class OfflineConfigPage extends StatefulWidget {
  const OfflineConfigPage({super.key});

  @override
  State<OfflineConfigPage> createState() => _OfflineConfigPageState();
}

class _OfflineConfigPageState extends State<OfflineConfigPage> {
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
  void initState() {
    super.initState();
    // 自动获取远程离线包列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPackages();
    });
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _visitUrlController.dispose();
    _bisNameController.dispose();
    super.dispose();
  }

  Future<void> _directNavigate() {
    final l10n = AppLocalizations.of(context)!;
    final visitUrl = _visitUrlController.text.trim();
    final bisName = _bisNameController.text.trim();

    if (visitUrl.isEmpty || bisName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.pleaseFillServerAndBisName)));
      return Future.value();
    }

    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FloatingPerformancePanel(
          child: OfflineWebPage(visitUrl: visitUrl),
        ),
      ),
    );
  }

  Future<void> _fetchPackages() async {
    final l10n = AppLocalizations.of(context)!;
    final serverUrl = _serverUrlController.text.trim();
    if (serverUrl.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.pleaseFillAccessAddress)));
      return;
    }

    setState(() => _isFetchingPackages = true);

    try {
      final uri = Uri.parse(serverUrl);
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final packages =
            (json['packages'] as List<dynamic>?)?.cast<String>() ?? [];

        if (!mounted) return;
        setState(() {
          _availablePackages = packages;
        });

        if (packages.isEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.noOfflinePackageData)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.fetchedPackagesCount(packages.length, packages.join(", "))),
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.requestFailed(response.statusCode))));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.fetchOfflinePackageFailed(e.toString()))));
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
      final baseUrl = _visitUrlController.text.split('?').first;
      _visitUrlController.text = '$baseUrl?offweb=$package';
    });
  }

  Future<void> _startOfflineLoading() async {
    final l10n = AppLocalizations.of(context)!;
    final serverUrl = _serverUrlController.text.trim();
    final visitUrl = _visitUrlController.text.trim();
    final bisName = _bisNameController.text.trim();

    if (serverUrl.isEmpty || visitUrl.isEmpty || bisName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.pleaseFillAllFields)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      OfflineWebClient.setRequest(_LocalServerRequest());

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FloatingPerformancePanel(
            child: OfflineWebPage(visitUrl: visitUrl),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Logger.e('CustomURL', '$e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.initFailed(e.toString()))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startNormalLoading() async {
    final l10n = AppLocalizations.of(context)!;
    final visitUrl = _visitUrlController.text.trim();
    if (visitUrl.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.pleaseFillAccessAddress)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnlineWebPage(url: visitUrl),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customConfigPage),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 服务器配置
            _buildSectionHeader(l10n.serverConfig, Icons.cloud_download, Colors.blue),
            const SizedBox(height: 12),
            _buildInputCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _serverUrlController,
                    label: l10n.offlinePackageServerAddress,
                    hint: l10n.exampleServerAddress,
                    icon: Icons.dns,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed:
                          _isFetchingPackages ? null : _fetchPackages,
                      child: _isFetchingPackages
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.getOfflinePackageList),
                              ],
                            ),
                    ),
                  ),
                  if (_availablePackages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPackage,
                      decoration: InputDecoration(
                        labelText: l10n.selectOfflinePackage,
                        prefixIcon: Icon(Icons.inventory_2, size: 20),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      hint: Text(l10n.pleaseSelectPackage),
                      items: _availablePackages
                          .map((pkg) => DropdownMenuItem(
                              value: pkg, child: Text(pkg)))
                          .toList(),
                      onChanged: _onPackageSelected,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 业务配置
            _buildSectionHeader(l10n.businessConfig, Icons.settings, Colors.purple),
            const SizedBox(height: 12),
            _buildInputCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _bisNameController,
                    label: l10n.businessName,
                    hint: l10n.examplePackage,
                    icon: Icons.label,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _visitUrlController,
                    label: l10n.accessAddress,
                    hint: l10n.exampleAccessAddress,
                    icon: Icons.link,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 加载方式
            _buildSectionHeader(l10n.loadingMethod, Icons.play_arrow, Colors.green),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.offline_bolt,
              title: l10n.useOfflinePackageLoading,
              description: l10n.useOfflinePackageLoadingDesc,
              color: Colors.green,
              buttonText: l10n.launch,
              isLoading: _isLoading,
              onPressed: _startOfflineLoading,
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.language,
              title: l10n.doNotUseOfflinePackage,
              description: l10n.doNotUseOfflinePackageDesc,
              color: Colors.grey,
              buttonText: l10n.launch,
              isLoading: _isLoading,
              onPressed: _startNormalLoading,
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.open_in_new,
              title: l10n.directNavigate,
              description: l10n.directNavigateDesc,
              color: Colors.blue,
              buttonText: l10n.navigate,
              isLoading: _isLoading,
              onPressed: _directNavigate,
            ),

            const SizedBox(height: 24),

            // 工具
            _buildSectionHeader(l10n.tools, Icons.build, Colors.orange),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildToolButton(
                    icon: Icons.image,
                    label: l10n.viewScreenshotCache,
                    color: Colors.blue,
                    onPressed: () => _viewScreenshot(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToolButton(
                    icon: Icons.delete_outline,
                    label: l10n.cleanOfflinePackage,
                    color: Colors.red,
                    onPressed: _cleanOfflinePackage,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String buttonText,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: isLoading ? null : onPressed,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cleanOfflinePackage() async {
    final l10n = AppLocalizations.of(context)!;
    final bisName = _bisNameController.text.trim();
    if (bisName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.pleaseFillBisNameFirst)));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmClean),
        content: Text(l10n.confirmCleanPackageCache(bisName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await OfflineWebManager.instance.cleanBisName(bisName);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.cleanedPackageCache(bisName))));
  }

  Future<void> _viewScreenshot(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bisName = _bisNameController.text.trim();
    if (bisName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.pleaseFillBisNameFirst)));
      return;
    }
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final appDir = await getApplicationDocumentsDirectory();
    final file = File(
        p.join(appDir.path, 'offline_web', bisName, 'cur', 'screenshot.png'));
    if (!file.existsSync()) {
      if (!mounted) return;
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text(l10n.screenshotNotExists(file.path))));
      return;
    }
    final bytes = file.readAsBytesSync();
    if (!mounted) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => _ScreenshotViewer(bytes: bytes, path: file.path, l10n: l10n),
      ),
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
              'Server returned status ${response.statusCode}: ${response.body}'),
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
  final AppLocalizations l10n;

  const _ScreenshotViewer({required this.bytes, required this.path, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenshotView),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              l10n.sizeBytes(bytes.length, path),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Center(
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (_, error, __) => Text(l10n.imageLoadFailed(error.toString())),
              ),
            ),
          ),
        ],
      ),
    );
  }
}