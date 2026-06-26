package com.laalkhata.app

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val smsChannelName = "laalkhata/sms"
    private val smsPermissionRequestCode = 7042
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, smsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "permissionStatus" -> result.success(permissionPayload())
                    "requestPermission" -> requestSmsPermission(result)
                    "readRecentSms" -> {
                        val limit = call.argument<Int>("limit") ?: 80
                        result.success(readRecentSms(limit))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == smsPermissionRequestCode) {
            permissionResult?.success(permissionPayload())
            permissionResult = null
        }
    }

    private fun requestSmsPermission(result: MethodChannel.Result) {
        if (hasSmsPermission()) {
            result.success(permissionPayload())
            return
        }

        permissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS),
            smsPermissionRequestCode
        )
    }

    private fun permissionPayload(): Map<String, Boolean> {
        return mapOf(
            "granted" to hasSmsPermission(),
            "canAsk" to ActivityCompat.shouldShowRequestPermissionRationale(
                this,
                Manifest.permission.READ_SMS
            ).not()
        )
    }

    private fun hasSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun readRecentSms(limit: Int): List<Map<String, Any>> {
        if (!hasSmsPermission()) return emptyList()

        val safeLimit = limit.coerceIn(1, 200)
        val sms = mutableListOf<Map<String, Any>>()
        val projection = arrayOf("address", "body", "date")
        val cursor = contentResolver.query(
            Uri.parse("content://sms/inbox"),
            projection,
            null,
            null,
            "date DESC"
        ) ?: return emptyList()

        cursor.use {
            val senderIndex = it.getColumnIndex("address")
            val bodyIndex = it.getColumnIndex("body")
            val dateIndex = it.getColumnIndex("date")
            while (it.moveToNext() && sms.size < safeLimit) {
                val sender = it.getString(senderIndex) ?: continue
                val body = it.getString(bodyIndex) ?: continue
                val timestamp = it.getLong(dateIndex)
                sms.add(
                    mapOf(
                        "sender" to sender,
                        "body" to body,
                        "timestamp" to timestamp
                    )
                )
            }
        }

        return sms
    }
}
