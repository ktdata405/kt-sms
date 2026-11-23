package com.ktsms.app.kt_sms

import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.provider.Telephony

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        if (intent.action == Telephony.Sms.Intents.SMS_DELIVER_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (message in messages) {
                val address = message.displayOriginatingAddress ?: message.originatingAddress ?: "Unknown"
                val body = message.messageBody ?: ""
                val date = System.currentTimeMillis()

                val values = ContentValues().apply {
                    put(Telephony.Sms.ADDRESS, address)
                    put(Telephony.Sms.BODY, body)
                    put(Telephony.Sms.DATE, date)
                    put(Telephony.Sms.READ, 0)
                    put(Telephony.Sms.TYPE, Telephony.Sms.MESSAGE_TYPE_INBOX)
                }
                try {
                    context.contentResolver.insert(Telephony.Sms.CONTENT_URI, values)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
}
