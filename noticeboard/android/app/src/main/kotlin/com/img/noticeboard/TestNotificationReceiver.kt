package com.img.noticeboard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo

class TestNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) return
        NoticeNotifications.show(context, "Noticeboard 30-second test",
            "Scheduled local notification delivered. This was not sent by the server.")
    }
}
