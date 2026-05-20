import 'dart:io';

import '../core/offline_const.dart';
import '../download/downloader.dart';
import '../util/file_mgr.dart';
import '../util/file_util.dart';
import '../util/off_web_log.dart';
import 'resource_flow.dart';

/// Flow步骤：从服务器下载包zip文件。
///
/// 从flow的包信息中提取下载URL，确定目标目录和文件名，
/// 然后委托给[IDownloader]。
/// 成功后更新上报参数并继续管道。
class DownloadFlow implements IFlow {
  final ResourceFlow _flow;
  final IDownloader _downloader;
  final OfflineWebResultBlock? _resultBlock;

  DownloadFlow({
    required ResourceFlow flow,
    required IDownloader downloader,
    OfflineWebResultBlock? resultBlock,
  }) : _flow = flow,
       _downloader = downloader,
       _resultBlock = resultBlock;

  @override
  Future<void> process() async {
    const tag = 'DownloadFlow';
    Logger.d(tag, '下载流程开始');

    final packageInfo = _flow.packageInfo;
    if (packageInfo == null) {
      Logger.e(tag, 'packageInfo为空, 返回错误');
      _flow.error(Exception('packageInfo is null in DownloadFlow'));
      return;
    }

    final url = packageInfo.url;
    Logger.d(tag, '下载地址: $url');
    if (url.isEmpty) {
      Logger.e(tag, '下载地址为空, 返回错误');
      _flow.error(Exception('download URL is empty'));
      return;
    }

    // 获取此业务模块的bisDir
    final bisName = packageInfo.bisName;
    Logger.d(tag, '业务名称: $bisName');
    Logger.d(tag, '正在获取业务目录...');
    final bisDir = await FileMgr.getBisDir(bisName);
    Logger.d(tag, '业务目录: $bisDir');

    // 从bisName构建文件名
    final fileName = '${bisName}${OfflineFileName.zipSuffix}';
    Logger.d(tag, '文件名: $fileName');

    // 标记下载开始
    final reportParams = _flow.reportParams;
    reportParams?.downloadStart();
    Logger.d(tag, '调用下载器 - 下载地址: $url, 保存目录: $bisDir, 文件名: $fileName');

    // 下载文件
    await _downloader.download(
      url,
      bisDir,
      fileName,
      _DownloadCallback(
        onSuccess: (File file, bool isBrokenDown) async {
          Logger.i(tag, '下载成功 - 文件路径: ${file.path}, 断点下载: $isBrokenDown');
          reportParams?.downloadResult(true);
          reportParams?.isBrokenDownSet(isBrokenDown);

          final zipSize = FileUtil.getFileSize(file.path);
          Logger.d(tag, 'ZIP文件大小: $zipSize 字节');
          reportParams?.zipSizeSet(zipSize);

          _resultBlock?.call(
            OfflineWebResultEvent.downloadSuccess,
            bisName,
            'download success',
          );

        },
        onFail: (Object error) {
          Logger.e(tag, '下载失败 - 错误: $error');
          reportParams?.downloadResult(false, error.toString());
          _resultBlock?.call(
            OfflineWebResultEvent.downloadError,
            bisName,
            error.toString(),
          );
          _flow.error(error);
        },
      ),
    );
  }
}

/// 将结果委托给闭包的私有[DownloadCallback]实现。
class _DownloadCallback implements DownloadCallback {
  final Future<void> Function(File file, bool isBrokenDown) onSuccess;
  final void Function(Object error) onFail;

  _DownloadCallback({required this.onSuccess, required this.onFail});

  @override
  void success(File file, bool isBrokenDown) {
    onSuccess(file, isBrokenDown);
  }

  @override
  void fail(Object error) => onFail(error);
}
