import 'dart:io';

/// 下载文件的抽象接口。
abstract class IDownloader {
  /// 从[url]下载文件到[dir]/[fileName]。
  /// 通过[callback]报告结果。
  Future<void> download(
      String url, String dir, String fileName, DownloadCallback callback);
}

/// 下载结果的回调接口。
abstract class DownloadCallback {
  /// 下载成功时调用。
  /// [file]是下载的文件。[isBrokenDown]表示是否是断点续传。
  void success(File file, bool isBrokenDown);

  /// 下载失败时调用。
  void fail(Object error);
}
