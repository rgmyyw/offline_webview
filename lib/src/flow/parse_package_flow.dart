import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/offline_const.dart';
import '../util/file_mgr.dart';
import '../util/file_util.dart';
import '../util/off_web_log.dart';
import 'resource_flow.dart';

/// Flow步骤：解析（解压）下载的包到目标目录。
class ParsePackageFlow implements IFlow {
  final ResourceFlow _flow;
  final OfflineWebResultBlock? _resultBlock;

  ParsePackageFlow({
    required ResourceFlow flow,
    OfflineWebResultBlock? resultBlock,
  })  : _flow = flow,
        _resultBlock = resultBlock;

  @override
  Future<void> process() async {
    const tag = 'ParsePackageFlow';
    final packageInfo = _flow.packageInfo;
    if (packageInfo == null) {
      Logger.e(tag, 'packageInfo为空');
      _flow.error(Exception('packageInfo is null in ParsePackageFlow'));
      return;
    }

    final bisName = packageInfo.bisName;
    final bisDir = await FileMgr.getBisDir(bisName);

    final tempDir = Directory(p.join(bisDir, OfflineDirName.temp));
    final newDir = Directory(p.join(bisDir, OfflineDirName.newDir));
    final zipPath = p.join(bisDir, '${bisName}${OfflineFileName.zipSuffix}');

    final zipFile = File(zipPath);
    if (!zipFile.existsSync()) {
      Logger.e(tag, '[$bisName] zip不存在');
      _flow.reportParams?.unZipEnd(false, 'zip not found');
      _resultBlock?.call(OfflineWebResultEvent.unzipError, bisName, 'zip not found');
      _flow.error(Exception('zip not found for $bisName'));
      return;
    }

    final reportParams = _flow.reportParams;
    reportParams?.unZipStart();

    await FileUtil.deleteDir(tempDir);

    final unzipSuccess = await FileUtil.unzipFile(zipPath, tempDir.path);
    if (!unzipSuccess) {
      reportParams?.unZipEnd(false, 'unzip failed');
      Logger.e(tag, '[$bisName] 解压失败');
      _resultBlock?.call(OfflineWebResultEvent.unzipError, bisName, 'unzip failed');
      _flow.error(Exception('unzip failed for $bisName'));
      return;
    }

    if (newDir.existsSync()) {
      Logger.w(tag, '[$bisName] new目录已存在，先删除');
      await FileUtil.deleteDir(newDir);
    }

    final renamed = FileUtil.rename(tempDir, OfflineDirName.newDir);
    if (!renamed) {
      reportParams?.unZipEnd(false, 'rename temp to new failed');
      Logger.e(tag, '[$bisName] temp->new重命名失败');
      _resultBlock?.call(OfflineWebResultEvent.parseError, bisName, 'rename failed');
      _flow.error(Exception('rename temp -> new failed for $bisName'));
      return;
    }

    if (zipFile.existsSync()) {
      try {
        await zipFile.delete();
      } catch (_) {}
    }

    reportParams?.unZipEnd(true);
    _resultBlock?.call(OfflineWebResultEvent.unzipSuccess, bisName, 'unzip success');
  }
}
