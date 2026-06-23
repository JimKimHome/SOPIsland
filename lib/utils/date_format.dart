String formatLastRun(DateTime? time) {
  if (time == null) return '未执行';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final hm =
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  if (day == today) return '今天 $hm';
  if (day == today.subtract(const Duration(days: 1))) return '昨天 $hm';
  if (now.difference(time).inDays < 7) {
    return '${now.difference(time).inDays} 天前';
  }
  return '${time.month}/${time.day} $hm';
}
