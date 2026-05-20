import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/offline_const.dart';
import '../util/file_mgr.dart';
import '../util/file_util.dart';
import '../util/off_web_log.dart';
import 'resource_flow.dart';

/// Flow步骤：解析（解压）下载的包到目标目录。
///
/// 将zip解压到temp目录，然后交换到`new`目录。
/// 完成后清理temp和zip文件。
class ParsePackageFlow implements IFlow {
  final ResourceFlow _flow;
  final OfflineWebResultBlock? _resultBlock;

  ParsePackageFlow({
    required ResourceFlow flow,
    OfflineWebResultBlock? resultBlock,
  }) : _flow = flow,
       _resultBlock = resultBlock;

  @override
  Future<void> process() async {
    const tag = 'ParsePackageFlow';
    final packageInfo = _flow.packageInfo;
    if (packageInfo == null) {
      Logger.e(tag, 'packageInfo为空, 返回错误');
      _flow.error(Exception('packageInfo is null in ParsePackageFlow'));
      return;
    }

    final bisName = packageInfo.bisName;
    Logger.d(tag, '开始 - bisName: $bisName');

    final bisDir = await FileMgr.getBisDir(bisName);
    Logger.d(tag, 'bisDir: $bisDir');

    // 构建路径
    final tempDir = Directory(p.join(bisDir, OfflineDirName.temp));
    final newDir = Directory(p.join(bisDir, OfflineDirName.newDir));
    final zipPath = p.join(bisDir, '${bisName}${OfflineFileName.zipSuffix}');
    Logger.d(tag, 'zipPath: $zipPath');

    // 检查zip文件是否存在
    final zipFile = File(zipPath);
    Logger.d(
      tag,
      'zip存在: ${zipFile.existsSync()}, 大小: ${zipFile.existsSync() ? zipFile.lengthSync() : 0}',
    );

    // 如果zip文件不存在，说明下载未触发或失败
    // 我们不应该尝试解压 - 直接返回错误并停止流程
    if (!zipFile.existsSync()) {
      Logger.e(tag, 'zip文件不存在, 停止流程');
      _flow.reportParams?.unZipEnd(
        false,
        'zip file not found - download may have failed',
      );
      _resultBlock?.call(
        OfflineWebResultEvent.unzipError,
        bisName,
        'zip file not found',
      );
      _flow.error(
        Exception(
          'zip file not found for $bisName - download was not triggered or failed',
        ),
      );
      return;
    }

    // 标记解压开始
    final reportParams = _flow.reportParams;
    reportParams?.unZipStart();

    // 删除旧temp目录
    Logger.d(tag, '删除旧临时目录');
    await FileUtil.deleteDir(tempDir);

    // 解压到temp
    Logger.d(tag, '调用文件解压');
    final unzipSuccess = await FileUtil.unzipFile(zipPath, tempDir.path);
    Logger.d(tag, '解压结果: $unzipSuccess');
    if (!unzipSuccess) {
      reportParams?.unZipEnd(false, 'unzip failed');
      Logger.e(tag, '解压失败, 调用错误回调');
      _resultBlock?.call(
        OfflineWebResultEvent.unzipError,
        bisName,
        'unzip failed',
      );
      _flow.error(Exception('unzip failed for $bisName'));
      return;
    }

    // 删除已存在的new目录
    Logger.d(tag, '删除new目录, 是否存在: ${newDir.existsSync()}');
    await FileUtil.deleteDir(newDir);
    Logger.d(tag, 'new目录删除后: ${newDir.existsSync()}');

    // 将temp重命名为new
    Logger.d(
      tag,
      'tempDir路径: ${tempDir.path}, exists: ${tempDir.existsSync()}',
    );
    final renamed = FileUtil.rename(tempDir, OfflineDirName.newDir);
    Logger.d(tag, '重命名结果: $renamed');
    Logger.d(tag, 'new目录路径: ${newDir.path}, 存在: ${newDir.existsSync()}');

    if (!renamed) {
      reportParams?.unZipEnd(false, 'rename temp to new failed');
      Logger.e(tag, '重命名失败');
      _resultBlock?.call(
        OfflineWebResultEvent.parseError,
        bisName,
        'rename temp to new failed',
      );
      _flow.error(Exception('rename temp -> new failed for $bisName'));
      return;
    }

    // 删除zip文件
    if (zipFile.existsSync()) {
      try {
        await zipFile.delete();
      } catch (_) {
        // 非关键：zip清理失败不应阻塞流程
      }
    }

    // 更新上报参数
    reportParams?.unZipEnd(true);

    _resultBlock?.call(
      OfflineWebResultEvent.unzipSuccess,
      bisName,
      'unzip success',
    );

    Logger.i(tag, '解析完成');

    // 不要调用_flow.process() - 让ResourceFlow.process()中的for循环自然继续
  }
}
