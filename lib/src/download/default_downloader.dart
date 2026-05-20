import 'dart:io';

import 'package:http/http.dart' as http;

import '../util/off_web_log.dart';
import 'downloader.dart';

/// 使用`http`包的[IDownloader]默认实现。
class DefaultDownloader implements IDownloader {
  @override
  Future<void> download(
    String url,
    String dir,
    String fileName,
    DownloadCallback callback,
  ) async {
    const tag = 'DefaultDownloader';
    Logger.d(tag, '下载开始 - 下载地址: $url, 保存目录: $dir, 文件名: $fileName');
    try {
      Logger.d(tag, '正在发起HTTP请求...');
      final response = await http.get(Uri.parse(url));
      Logger.d(tag, 'HTTP请求完成 - 状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final directory = Directory(dir);
        if (!directory.existsSync()) {
          Logger.d(tag, '创建目录: $dir');
          directory.createSync(recursive: true);
        }

        final file = File('$dir/$fileName');
        Logger.d(tag, '写入文件: ${file.path}');
        await file.writeAsBytes(response.bodyBytes);
        Logger.d(tag, '文件写入成功，调用成功回调');
        callback.success(file, false);
        Logger.i(tag, '成功回调返回 - 文件大小: ${response.bodyBytes.length} bytes');
      } else {
        Logger.e(tag, 'HTTP请求失败 - 状态码: ${response.statusCode}');
        callback.fail(
          Exception('Download failed with status: ${response.statusCode}'),
        );
      }
    } catch (e) {
      Logger.e(tag, '下载异常: $e');
      callback.fail(e);
    }
  }
}
