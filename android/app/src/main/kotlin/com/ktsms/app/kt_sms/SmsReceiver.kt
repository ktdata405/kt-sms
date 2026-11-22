package com.ktsms.app.kt_sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        // Required for default SMS app role handling incoming SMS
    }
}
