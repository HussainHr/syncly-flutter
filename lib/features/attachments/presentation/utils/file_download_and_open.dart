import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class FileDownloadAndOpen {
  static Future<void> downloadAndOpen({
    required String url,
    required String fileName,
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '${dir.path}/$safeName';

    final file = File(path);
    if (!await file.exists()) {
      await Dio().download(
        url,
        path,
        onReceiveProgress: onProgress,
      );
    }

    await OpenFilex.open(path);
  }

  static Future<void> saveBytesAndOpen({
    required List<int> bytes,
    required String fileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '${dir.path}/$safeName';
    final file = File(path);
    if (!await file.exists()) {
      await file.writeAsBytes(bytes, flush: true);
    }
    await OpenFilex.open(path);
  }
}

