package com.ktsms.app.kt_sms

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.provider.Telephony

class SmsActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        val action = intent.action
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (action == "ACTION_MARK_READ") {
            val address = intent.getStringExtra("address")
            if (address != null) {
                val values = ContentValues().apply { put(Telephony.Sms.READ, 1) }
                context.contentResolver.update(
                    Telephony.Sms.CONTENT_URI,
                    values,
                    "${Telephony.Sms.ADDRESS} = ?",
                    arrayOf(address)
                )
            }
            notificationManager.cancelAll()
        } else if (action == "ACTION_DELETE_SMS") {
            val msgId = intent.getStringExtra("msg_id")
            if (msgId != null) {
                context.contentResolver.delete(
                    Telephony.Sms.CONTENT_URI,
                    "${Telephony.Sms._ID} = ?",
                    arrayOf(msgId)
                )
            }
            notificationManager.cancelAll()
        }
    }
}
