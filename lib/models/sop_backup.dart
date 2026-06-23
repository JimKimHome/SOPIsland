import 'dart:convert';

import 'sop.dart';

class SopBackup {
  SopBackup({required this.exportedAt, required this.sops});

  static const appName = 'OrSOP';
  static const format = 'orsop.sops';
  static const formatVersion = 1;

  final DateTime exportedAt;
  final List<Sop> sops;

  String toJsonString() {
    final data = {
      'app': appName,
      'format': format,
      'formatVersion': formatVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'sops': sops.map((sop) => sop.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  factory SopBackup.fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('备份文件格式不正确。');
    }
    final json = Map<String, dynamic>.from(decoded);
    final rawSops = json['sops'];
    if (rawSops is! List) {
      throw const FormatException('备份文件缺少 SOP 数据。');
    }
    return SopBackup(
      exportedAt:
          DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      sops: rawSops
          .map((item) => Sop.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}
