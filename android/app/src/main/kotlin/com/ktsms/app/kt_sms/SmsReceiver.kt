package com.ktsms.app.kt_sms

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.ContactsContract
import android.provider.Telephony
import androidx.core.app.NotificationCompat

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

                val senderName = getContactName(context, address)
                showNotification(context, senderName, body)
            }
        }
    }

    private fun getContactName(context: Context, address: String): String {
        try {
            val normalizedAddress = normalizeNumber(address)
            val cursor = context.contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                arrayOf(
                    ContactsContract.CommonDataKinds.Phone.NUMBER,
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME
                ),
                null,
                null,
                null
            )

            cursor?.use {
                val numCol = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                val nameCol = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                while (it.moveToNext()) {
                    val number = it.getString(numCol) ?: ""
                    val name = it.getString(nameCol) ?: ""
                    if (number.isNotEmpty() && name.isNotEmpty()) {
                        val normNumber = normalizeNumber(number)
                        if (normNumber == normalizedAddress || number == address) {
                            return name
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return address
    }

    private fun normalizeNumber(raw: String): String {
        val cleaned = raw.replace(Regex("[^0-9+]"), "")
        if (cleaned.isEmpty() || !cleaned.contains(Regex("[0-9]"))) {
            return raw.uppercase()
        }
        if (cleaned.length >= 10) {
            return cleaned.substring(cleaned.length - 10)
        }
        return cleaned
    }

    private fun showNotification(context: Context, sender: String, body: String) {
        val channelId = "kt_sms_incoming"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Incoming SMS", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Notifications for incoming text messages"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.sym_action_chat)
            .setContentTitle("New message from $sender")
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)

        notificationManager.notify(System.currentTimeMillis().toInt(), builder.build())
    }
}
