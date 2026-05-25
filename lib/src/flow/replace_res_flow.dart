import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/offline_const.dart';
import '../core/offline_web_manager.dart';
import '../util/file_mgr.dart';
import '../util/file_util.dart';
import '../util/off_web_log.dart';
import 'resource_flow.dart';

/// Flow步骤：用新下载的资源替换当前资源。
class ReplaceResFlow implements IFlow {
  final ResourceFlow _flow;
  final OfflineWebResultBlock? _resultBlock;

  ReplaceResFlow({
    required ResourceFlow flow,
    OfflineWebResultBlock? resultBlock,
  })  : _flow = flow,
        _resultBlock = resultBlock;

  @override
  Future<void> process() async {
    const tag = 'ReplaceResFlow';
    final packageInfo = _flow.packageInfo;
    if (packageInfo == null) {
      Logger.e(tag, 'packageInfo为null');
      _flow.error(Exception('packageInfo is null in ReplaceResFlow'));
      return;
    }

    final bisName = packageInfo.bisName;
    _flow.reportParams?.replaceStart();

    final bisDir = await FileMgr.getBisDir(bisName);
    final curDir = Directory(p.join(bisDir, OfflineDirName.cur));
    final newDir = Directory(p.join(bisDir, OfflineDirName.newDir));
    final oldDir = Directory(p.join(bisDir, OfflineDirName.old));

    if (packageInfo.isForceRefresh) {
      Logger.i(tag, '[$bisName] 强制刷新');
      await _doForceRefresh(curDir, newDir, oldDir, bisName);
    } else {
      Logger.i(tag, '[$bisName] 普通刷新');
      await _doNormalRefresh(curDir, newDir, bisName);
    }

    _flow.reportParams?.replaceEnd(true);
  }

  Future<void> _doForceRefresh(
    Directory curDir,
    Directory newDir,
    Directory oldDir,
    String bisName,
  ) async {
    if (curDir.existsSync()) {
      await FileUtil.deleteDir(oldDir);
      FileUtil.rename(curDir, OfflineDirName.old);
    }

    if (newDir.existsSync()) {
      FileUtil.rename(newDir, OfflineDirName.cur);
    }

    OfflineWebManager.instance.pageManager.reload(bisName);

    _resultBlock?.call(
      OfflineWebResultEvent.refreshPackageNow,
      bisName,
      'force refresh done',
    );
  }

  Future<void> _doNormalRefresh(
    Directory curDir,
    Directory newDir,
    String bisName,
  ) async {
    const tag = 'ReplaceResFlow';

    if (newDir.existsSync()) {
      if (curDir.existsSync()) {
        Logger.i(tag, '[$bisName] cur已存在，删除旧cur');
        await FileUtil.deleteDir(curDir);
      }

      final renameResult = FileUtil.rename(newDir, OfflineDirName.cur);
      if (!renameResult) {
        Logger.e(tag, '[$bisName] new->cur重命名失败');
      }

      OfflineWebManager.instance.refreshCurPathCache(bisName);

      _resultBlock?.call(
        OfflineWebResultEvent.refreshPackageNow,
        bisName,
        'refresh done',
      );
    } else if (!curDir.existsSync()) {
      Logger.w(tag, '[$bisName] new和cur均不存在');
      _resultBlock?.call(
        OfflineWebResultEvent.refreshPackageLater,
        bisName,
        'no package available',
      );
    } else {
      _resultBlock?.call(
        OfflineWebResultEvent.refreshPackageLater,
        bisName,
        'package will refresh on next startup',
      );
    }
  }
}
