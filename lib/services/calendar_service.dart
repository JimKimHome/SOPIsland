import 'package:flutter/services.dart';

import '../models/sop.dart';

class CalendarService {
  CalendarService._();

  static const _channel = MethodChannel('com.sopisland.app/calendar');

  static Future<void> createSopReminder(Sop sop) async {
    final reminder = sop.reminder;
    if (reminder == null) return;
    await _channel.invokeMethod<void>('createCalendarEvent', {
      'title': 'SOP：${sop.title}',
      'description': _descriptionFor(sop),
      'startMillis': reminder.startsAt.millisecondsSinceEpoch,
      'endMillis': reminder.startsAt
          .add(const Duration(minutes: 30))
          .millisecondsSinceEpoch,
      'rrule': _rruleFor(reminder),
      'alertMinutes': reminder.alertMinutes,
    });
  }

  static String _descriptionFor(Sop sop) {
    final buffer = StringBuffer()
      ..writeln(sop.description.trim().isEmpty ? sop.scene : sop.description)
      ..writeln()
      ..writeln('来自 OrSOP');
    for (var i = 0; i < sop.steps.length; i++) {
      buffer.writeln('${i + 1}. ${sop.steps[i].title}');
      for (final item in sop.steps[i].items) {
        buffer.writeln('   - $item');
      }
    }
    return buffer.toString().trim();
  }

  static String? _rruleFor(SopReminder reminder) {
    final freq = reminder.repeat.rruleFreq;
    if (freq == null) return null;
    final until = reminder.endsAt;
    if (until == null) return 'FREQ=$freq';
    final utc = DateTime.utc(until.year, until.month, until.day, 23, 59, 59);
    final stamp =
        '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}'
        'T235959Z';
    return 'FREQ=$freq;UNTIL=$stamp';
  }
}
