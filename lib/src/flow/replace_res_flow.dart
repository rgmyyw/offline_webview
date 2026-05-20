import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/offline_const.dart';
import '../core/offline_web_manager.dart';
import '../util/file_mgr.dart';
import '../util/file_util.dart';
import '../util/off_web_log.dart';
import 'resource_flow.dart';

/// Flow步骤：用新下载的资源替换当前资源。
///
/// 处理两种场景：
/// - **强制刷新**（refreshMode == 1）：立即交换cur->old和new->cur，
///   然后触发页面重新加载。
/// - **非强制**：如果`cur`不存在，直接交换new->cur。
///   如果`cur`已存在，则不执行任何操作（等待下次启动时拾取`new`）。
class ReplaceResFlow implements IFlow {
  final ResourceFlow _flow;
  final OfflineWebResultBlock? _resultBlock;

  ReplaceResFlow({
    required ResourceFlow flow,
    OfflineWebResultBlock? resultBlock,
  }) : _flow = flow,
       _resultBlock = resultBlock;

  @override
  Future<void> process() async {
    const tag = 'ReplaceResFlow';
    Logger.d(tag, '开始');
    final packageInfo = _flow.packageInfo;
    if (packageInfo == null) {
      Logger.e(tag, 'packageInfo为null');
      _flow.error(Exception('packageInfo is null in ReplaceResFlow'));
      return;
    }

    final bisName = packageInfo.bisName;
    Logger.d(
      tag,
      'bisName: $bisName, isForceRefresh: ${packageInfo.isForceRefresh}',
    );

    final bisDir = await FileMgr.getBisDir(bisName);
    final curDir = Directory(p.join(bisDir, OfflineDirName.cur));
    final newDir = Directory(p.join(bisDir, OfflineDirName.newDir));
    final oldDir = Directory(p.join(bisDir, OfflineDirName.old));

    if (packageInfo.isForceRefresh) {
      // 强制刷新：cur -> old, new -> cur, 然后重新加载WebView
      Logger.d(tag, '执行强制刷新');
      await _doForceRefresh(curDir, newDir, oldDir, bisName);
    } else {
      // 非强制刷新
      Logger.d(tag, '执行普通刷新');
      await _doNormalRefresh(curDir, newDir, bisName);
    }

    // 不要调用_flow.process() - 让ResourceFlow.process()中的for循环自然继续
    // ResourceFlow在所有flows完成后会调用setDone()
  }

  /// 强制刷新：将cur移至old，将new移至cur，触发页面重新加载。
  Future<void> _doForceRefresh(
    Directory curDir,
    Directory newDir,
    Directory oldDir,
    String bisName,
  ) async {
    if (curDir.existsSync()) {
      // 删除旧目录，然后将cur移至old
      await FileUtil.deleteDir(oldDir);
      FileUtil.rename(curDir, OfflineDirName.old);
    }

    if (newDir.existsSync()) {
      // 将new移至cur
      FileUtil.rename(newDir, OfflineDirName.cur);
    }

    // 触发此bisName的WebView重新加载。
    OfflineWebManager.instance.pageManager.reload(bisName);

    _resultBlock?.call(
      OfflineWebResultEvent.refreshPackageNow,
      bisName,
      'force refresh done',
    );
  }

  /// 普通（非强制）刷新逻辑。
  Future<void> _doNormalRefresh(
    Directory curDir,
    Directory newDir,
    String bisName,
  ) async {
    const tag = 'ReplaceResFlow';
    Logger.d(tag, '普通刷新开始 - bisName: $bisName');
    Logger.d(tag, 'newDir路径: ${newDir.path}, exists: ${newDir.existsSync()}');
    Logger.d(tag, 'curDir路径: ${curDir.path}, exists: ${curDir.existsSync()}');

    // 当new存在时，始终交换new -> cur，不管cur状态如何。
    // 这确保用户在下载完成后立即看到最新内容。
    if (newDir.existsSync()) {
      Logger.d(tag, 'newDir存在，开始替换');

      if (curDir.existsSync()) {
        Logger.d(tag, 'curDir存在，删除旧cur');
        await FileUtil.deleteDir(curDir);
      }

      Logger.d(tag, '执行new目录重命名为cur');
      final renameResult = FileUtil.rename(newDir, OfflineDirName.cur);
      Logger.d(tag, '重命名结果: $renameResult');

      // 验证重命名是否成功
      if (curDir.existsSync()) {
        Logger.d(tag, 'curDir存在验证: 成功');
        final htmlFile = File(p.join(curDir.path, OfflineFileName.html));
        Logger.d(tag, 'cur/index.html 存在: ${htmlFile.existsSync()}');
      } else {
        Logger.e(tag, 'curDir存在验证: 失败! curDir不存在');
      }

      // 重命名成功后更新缓存
      OfflineWebManager.instance.refreshCurPathCache(bisName);

      _resultBlock?.call(
        OfflineWebResultEvent.refreshPackageNow,
        bisName,
        'refresh done',
      );
    } else if (!curDir.existsSync()) {
      // 没有新包且没有cur：无需操作
      Logger.w(tag, 'newDir不存在且curDir不存在，无包可用');
      _resultBlock?.call(
        OfflineWebResultEvent.refreshPackageLater,
        bisName,
        'no package available',
      );
    } else {
      // cur存在但没有新包 - 保留cur，new将在下次启动时被拾取
      Logger.d(tag, 'newDir不存在，curDir存在，下次启动刷新');
      _resultBlock?.call(
        OfflineWebResultEvent.refreshPackageLater,
        bisName,
        'package will refresh on next startup',
      );
    }

    Logger.d(tag, '普通刷新结束');
  }
}
