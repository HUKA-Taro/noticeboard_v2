package com.img.noticeboard

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

object NoticeNotifications {
    private const val CHANNEL = "noticeboard_alerts"

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= 26) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(NotificationChannel(
                CHANNEL, "Noticeboard alerts", NotificationManager.IMPORTANCE_HIGH))
        }
    }

    fun canNotify(context: Context): Boolean {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return manager.areNotificationsEnabled() && (Build.VERSION.SDK_INT < 33 ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
    }

    fun show(context: Context, title: String?, body: String?) {
        if (!canNotify(context)) return
        createChannel(context)
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pendingIntent = PendingIntent.getActivity(context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL)
            else Notification.Builder(context)
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), builder
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title ?: "Noticeboard")
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setPriority(Notification.PRIORITY_HIGH)
            .setDefaults(Notification.DEFAULT_ALL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build())
    }
}
