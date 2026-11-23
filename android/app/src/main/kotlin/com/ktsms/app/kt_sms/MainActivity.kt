package com.ktsms.app.kt_sms

import android.app.role.RoleManager
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.provider.Telephony
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.ktsms.app/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSmsMessages" -> result.success(readSmsMessages())
                "getThreadMessages" -> {
                    val threadId = call.argument<String>("threadId")
                    val address = call.argument<String>("address")
                    result.success(readSmsMessages(threadId = threadId, address = address))
                }
                "markThreadAsRead" -> {
                    try {
                        val threadId = call.argument<String>("threadId")
                        val address = call.argument<String>("address")
                        val rows = markThreadAsRead(threadId = threadId, address = address)
                        result.success(rows > 0)
                    } catch (e: Exception) {
                        result.error("MARK_READ_ERROR", e.message, null)
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
                                    if (number.length >= 10) contacts[number.takeLast(10)] = name
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
                    if (address.isNullOrBlank() || body.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENTS", "Address and body cannot be null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            applicationContext.getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }

                        if (body.length > 160) {
                            val parts = smsManager?.divideMessage(body)
                            smsManager?.sendMultipartTextMessage(address.trim(), null, parts, null, null)
                        } else {
                            smsManager?.sendTextMessage(address.trim(), null, body, null, null)
                        }

                        // Insert sent message into system content provider so it shows in conversation history
                        val values = ContentValues().apply {
                            put(Telephony.Sms.ADDRESS, address.trim())
                            put(Telephony.Sms.BODY, body)
                            put(Telephony.Sms.DATE, System.currentTimeMillis())
                            put(Telephony.Sms.READ, 1)
                            put(Telephony.Sms.TYPE, Telephony.Sms.MESSAGE_TYPE_SENT)
                        }
                        try {
                            contentResolver.insert(Uri.parse("content://sms/sent"), values)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SMS_SEND_ERROR", e.message, null)
                    }
                }
                "isDefaultSmsApp" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val roleManager = getSystemService(RoleManager::class.java)
                            if (roleManager?.isRoleAvailable(RoleManager.ROLE_SMS) == true) {
                                result.success(roleManager.isRoleHeld(RoleManager.ROLE_SMS))
                                return@setMethodCallHandler
                            }
                        }

                        val defaultSmsPackage = Telephony.Sms.getDefaultSmsPackage(applicationContext)
                        result.success(defaultSmsPackage == packageName)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "requestDefaultSmsApp" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val roleManager = getSystemService(RoleManager::class.java)
                            if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_SMS)) {
                                startActivityForResult(roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS), 200)
                                result.success(true)
                                return@setMethodCallHandler
                            }
                        }

                        val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
                        intent.putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, packageName)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DEFAULT_SMS_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun readSmsMessages(threadId: String? = null, address: String? = null): List<Map<String, Any>> {
        return try {
            val messages = mutableListOf<Map<String, Any>>()
            val uri = Uri.parse("content://sms")
            val projection = arrayOf(
                Telephony.Sms._ID,
                Telephony.Sms.THREAD_ID,
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
                Telephony.Sms.TYPE,
                Telephony.Sms.READ
            )

            val selection: String?
            val args: Array<String>?
            when {
                !threadId.isNullOrBlank() -> {
                    selection = "${Telephony.Sms.THREAD_ID} = ?"
                    args = arrayOf(threadId)
                }
                !address.isNullOrBlank() -> {
                    selection = "${Telephony.Sms.ADDRESS} = ?"
                    args = arrayOf(address)
                }
                else -> {
                    selection = null
                    args = null
                }
            }

            val order = if (threadId != null || address != null) {
                "${Telephony.Sms.DATE} ASC"
            } else {
                Telephony.Sms.DEFAULT_SORT_ORDER
            }

            val cursor = contentResolver.query(uri, projection, selection, args, order)
            cursor?.use {
                val idCol = it.getColumnIndex(Telephony.Sms._ID)
                val threadCol = it.getColumnIndex(Telephony.Sms.THREAD_ID)
                val addressCol = it.getColumnIndex(Telephony.Sms.ADDRESS)
                val bodyCol = it.getColumnIndex(Telephony.Sms.BODY)
                val dateCol = it.getColumnIndex(Telephony.Sms.DATE)
                val typeCol = it.getColumnIndex(Telephony.Sms.TYPE)
                val readCol = it.getColumnIndex(Telephony.Sms.READ)

                while (it.moveToNext()) {
                    messages.add(
                        mapOf(
                            "id" to if (idCol >= 0) it.getString(idCol) else "",
                            "threadId" to if (threadCol >= 0) it.getString(threadCol) else "",
                            "address" to if (addressCol >= 0) (it.getString(addressCol) ?: "Unknown") else "Unknown",
                            "body" to if (bodyCol >= 0) (it.getString(bodyCol) ?: "") else "",
                            "date" to if (dateCol >= 0) it.getLong(dateCol) else 0L,
                            "type" to if (typeCol >= 0) it.getInt(typeCol) else 1,
                            "read" to if (readCol >= 0) it.getInt(readCol) == 1 else true
                        )
                    )
                }
            }
            messages
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun markThreadAsRead(threadId: String? = null, address: String? = null): Int {
        val uri = Uri.parse("content://sms/sent")
        val values = ContentValues().apply { put(Telephony.Sms.READ, 1) }

        val selection: String?
        val args: Array<String>?
        when {
            !threadId.isNullOrBlank() -> {
                selection = "${Telephony.Sms.THREAD_ID} = ? AND ${Telephony.Sms.READ} = 0"
                args = arrayOf(threadId)
            }
            !address.isNullOrBlank() -> {
                selection = "${Telephony.Sms.ADDRESS} = ? AND ${Telephony.Sms.READ} = 0"
                args = arrayOf(address)
            }
            else -> {
                selection = null
                args = null
            }
        }

        return contentResolver.update(Uri.parse("content://sms"), values, selection, args)
    }
}
