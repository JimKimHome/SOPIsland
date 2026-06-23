package com.sopisland.app;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.provider.CalendarContract;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.TimeZone;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CALENDAR_CHANNEL = "com.sopisland.app/calendar";
    private static final String BACKUP_CHANNEL = "com.sopisland.app/backup";
    private static final int REQUEST_CREATE_BACKUP = 4101;
    private static final int REQUEST_OPEN_BACKUP = 4102;
    private MethodChannel.Result pendingBackupResult;
    private String pendingBackupContent;

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CALENDAR_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if (!"createCalendarEvent".equals(call.method)) {
                    result.notImplemented();
                    return;
                }
                try {
                    openCalendarInsert(call.argument("title"),
                        call.argument("description"),
                        call.argument("startMillis"),
                        call.argument("endMillis"),
                        call.argument("rrule"),
                        call.argument("alertMinutes"));
                    result.success(null);
                } catch (ActivityNotFoundException error) {
                    result.error("calendar_unavailable", "没有找到可用的日历应用。", null);
                } catch (Exception error) {
                    result.error("calendar_error", error.getMessage(), null);
                }
            });
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), BACKUP_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if ("saveBackup".equals(call.method)) {
                    if (pendingBackupResult != null) {
                        result.error("backup_busy", "已有备份操作正在进行。", null);
                        return;
                    }
                    try {
                        pendingBackupResult = result;
                        pendingBackupContent = call.argument("content");
                        openBackupCreate(call.argument("fileName"));
                    } catch (ActivityNotFoundException error) {
                        clearPendingBackup();
                        result.error("file_picker_unavailable", "没有找到可用的文件管理器。", null);
                    } catch (Exception error) {
                        clearPendingBackup();
                        result.error("backup_error", error.getMessage(), null);
                    }
                    return;
                }
                if ("openBackup".equals(call.method)) {
                    if (pendingBackupResult != null) {
                        result.error("backup_busy", "已有备份操作正在进行。", null);
                        return;
                    }
                    try {
                        pendingBackupResult = result;
                        openBackupPicker();
                    } catch (ActivityNotFoundException error) {
                        clearPendingBackup();
                        result.error("file_picker_unavailable", "没有找到可用的文件管理器。", null);
                    } catch (Exception error) {
                        clearPendingBackup();
                        result.error("backup_error", error.getMessage(), null);
                    }
                    return;
                }
                result.notImplemented();
            });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != REQUEST_CREATE_BACKUP && requestCode != REQUEST_OPEN_BACKUP) {
            return;
        }
        MethodChannel.Result result = pendingBackupResult;
        if (result == null) return;
        try {
            if (resultCode != RESULT_OK || data == null || data.getData() == null) {
                result.success(requestCode == REQUEST_CREATE_BACKUP ? false : null);
                return;
            }
            Uri uri = data.getData();
            if (requestCode == REQUEST_CREATE_BACKUP) {
                writeText(uri, pendingBackupContent == null ? "" : pendingBackupContent);
                result.success(true);
            } else {
                result.success(readText(uri));
            }
        } catch (Exception error) {
            result.error("backup_error", error.getMessage(), null);
        } finally {
            clearPendingBackup();
        }
    }

    private void openCalendarInsert(
        String title,
        String description,
        Long startMillis,
        Long endMillis,
        String rrule,
        Integer alertMinutes
    ) {
        Intent intent = new Intent(Intent.ACTION_INSERT)
            .setData(CalendarContract.Events.CONTENT_URI)
            .putExtra(CalendarContract.Events.TITLE, title)
            .putExtra(CalendarContract.Events.DESCRIPTION, description)
            .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startMillis)
            .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endMillis)
            .putExtra(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().getID())
            .putExtra(CalendarContract.Events.HAS_ALARM, true)
            .putExtra(CalendarContract.Reminders.MINUTES, alertMinutes == null ? 10 : alertMinutes);

        if (rrule != null && !rrule.isEmpty()) {
            intent.putExtra(CalendarContract.Events.RRULE, rrule);
        }

        startActivity(intent);
    }

    private void openBackupCreate(String fileName) {
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("application/json")
            .putExtra(Intent.EXTRA_TITLE, fileName == null || fileName.isEmpty()
                ? "OrSOP-backup.orsop.json"
                : fileName);
        startActivityForResult(intent, REQUEST_CREATE_BACKUP);
    }

    private void openBackupPicker() {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*");
        String[] mimeTypes = new String[] {"application/json", "text/json", "text/plain", "application/octet-stream"};
        intent.putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes);
        startActivityForResult(intent, REQUEST_OPEN_BACKUP);
    }

    private void writeText(Uri uri, String content) throws Exception {
        try (OutputStream stream = getContentResolver().openOutputStream(uri, "wt")) {
            if (stream == null) throw new Exception("无法写入备份文件。");
            stream.write(content.getBytes(StandardCharsets.UTF_8));
        }
    }

    private String readText(Uri uri) throws Exception {
        try (InputStream stream = getContentResolver().openInputStream(uri)) {
            if (stream == null) throw new Exception("无法读取备份文件。");
            ByteArrayOutputStream buffer = new ByteArrayOutputStream();
            byte[] chunk = new byte[8192];
            int read;
            while ((read = stream.read(chunk)) != -1) {
                buffer.write(chunk, 0, read);
            }
            return new String(buffer.toByteArray(), StandardCharsets.UTF_8);
        }
    }

    private void clearPendingBackup() {
        pendingBackupResult = null;
        pendingBackupContent = null;
    }
}
