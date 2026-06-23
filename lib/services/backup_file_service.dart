import 'package:flutter/services.dart';

class BackupFileService {
  BackupFileService._();

  static const _channel = MethodChannel('com.sopisland.app/backup');

  static Future<bool> saveBackup({
    required String fileName,
    required String content,
  }) async {
    final saved = await _channel.invokeMethod<bool>('saveBackup', {
      'fileName': fileName,
      'content': content,
    });
    return saved ?? false;
  }

  static Future<String?> openBackup() {
    return _channel.invokeMethod<String>('openBackup');
  }
}
