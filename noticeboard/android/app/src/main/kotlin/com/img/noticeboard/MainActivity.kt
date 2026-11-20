package com.img.noticeboard

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.SystemClock

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NoticeNotifications.createChannel(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "noticeboard/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method != "show" && call.method != "scheduleTest") {
                    result.notImplemented()
                } else if (!NoticeNotifications.canNotify(this)) {
                    result.error("permission_denied", "Enable notifications in Android app settings first.", null)
                } else if (call.method == "scheduleTest") {
                    if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) {
                        result.notImplemented()
                        return@setMethodCallHandler
                    }
                    val alarms = getSystemService(ALARM_SERVICE) as AlarmManager
                    if (Build.VERSION.SDK_INT >= 31 && !alarms.canScheduleExactAlarms()) {
                        result.error("exact_alarm_denied", "Allow alarms for Noticeboard in Android settings, then retry.", null)
                    } else {
                        val pendingIntent = PendingIntent.getBroadcast(this, 30,
                            Intent(this, TestNotificationReceiver::class.java),
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                        alarms.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP,
                            SystemClock.elapsedRealtime() + 30_000, pendingIntent)
                        result.success(null)
                    }
                } else {
                    NoticeNotifications.show(this, call.argument<String>("title"), call.argument<String>("body"))
                    result.success(null)
                }
            }
    }
}
