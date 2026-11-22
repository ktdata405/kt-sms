package com.ktsms.app.kt_sms

import android.content.ContentValues
import android.net.Uri
import android.provider.ContactsContract
import android.provider.Telephony
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ktsms.app/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSmsMessages" -> {
                    try {
                        val messages = mutableListOf<Map<String, Any>>()
                        val uri = Uri.parse("content://sms")
                        val cursor = contentResolver.query(
                            uri,
                            arrayOf(
                                Telephony.Sms._ID,
                                Telephony.Sms.THREAD_ID,
                                Telephony.Sms.ADDRESS,
                                Telephony.Sms.BODY,
                                Telephony.Sms.DATE,
                                Telephony.Sms.TYPE,
                                Telephony.Sms.READ,
                                Telephony.Sms.STATUS
                            ),
                            null,
                            null,
                            Telephony.Sms.DEFAULT_SORT_ORDER
                        )

                        cursor?.use {
                            val idCol = it.getColumnIndex(Telephony.Sms._ID)
                            val threadCol = it.getColumnIndex(Telephony.Sms.THREAD_ID)
                            val addressCol = it.getColumnIndex(Telephony.Sms.ADDRESS)
                            val bodyCol = it.getColumnIndex(Telephony.Sms.BODY)
                            val dateCol = it.getColumnIndex(Telephony.Sms.DATE)
                            val typeCol = it.getColumnIndex(Telephony.Sms.TYPE)
                            val readCol = it.getColumnIndex(Telephony.Sms.READ)

                            while (it.moveToNext()) {
                                val msg = mapOf(
                                    "id" to if (idCol >= 0) it.getString(idCol) else "",
                                    "threadId" to if (threadCol >= 0) it.getString(threadCol) else "",
                                    "address" to if (addressCol >= 0) (it.getString(addressCol) ?: "Unknown") else "Unknown",
                                    "body" to if (bodyCol >= 0) (it.getString(bodyCol) ?: "") else "",
                                    "date" to if (dateCol >= 0) it.getLong(dateCol) else 0L,
                                    "type" to if (typeCol >= 0) it.getInt(typeCol) else 1,
                                    "read" to if (readCol >= 0) it.getInt(readCol) == 1 else true
                                )
                                messages.add(msg)
                            }
                        }
                        result.success(messages)
                    } catch (e: Exception) {
                        result.error("SMS_READ_ERROR", e.message, null)
                    }
                }
                "getContacts" -> {
                    try {
                        val contacts = mutableMapOf<String, String>()
                        val cursor = contentResolver.query(
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
                                val number = it.getString(numCol)?.replace(Regex("[^0-9+]"), "") ?: ""
                                val name = it.getString(nameCol) ?: ""
                                if (number.isNotEmpty() && name.isNotEmpty()) {
                                    contacts[number] = name
                                    // Also store last 10 digits for matching
                                    if (number.length >= 10) {
                                        contacts[number.takeLast(10)] = name
                                    }
                                }
                            }
                        }
                        result.success(contacts)
                    } catch (e: Exception) {
                        result.error("CONTACTS_READ_ERROR", e.message, null)
                    }
                }
                "sendSms" -> {
                    val address = call.argument<String>("address")
                    val body = call.argument<String>("body")
                    if (address != null && body != null) {
                        try {
                            val smsManager = context.getSystemService(SmsManager::class.java)
                            smsManager.sendTextMessage(address, null, body, null, null)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SMS_SEND_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Address and body cannot be null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
