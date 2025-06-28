package com.example.real_time

import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.core.net.toUri
import androidx.lifecycle.viewmodel.CreationExtras
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity()
{
    companion object {
        private val CHANNEL = "open_apps_channel"
    }
    
    private fun openAppByPackageName(packageNmae: String?): Boolean {
        try {
            // if app is install direct open it
            if(packageNmae.isNullOrEmpty()) {
                Log.d("APP_OPENER", "openAppByPackageName: packageName is null", null)
                return false
            }
            val intent: Intent? = packageManager.getLaunchIntentForPackage(packageNmae)

            if(intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            }
            else {
                // app is not installed
                val marketIntent = Intent(Intent.ACTION_VIEW, Uri.parse("market://detail?id=${packageNmae!!}"))
                try {
                    // use try for some device market:// can fail if play store not exsits
                    startActivity(marketIntent)
                    return true
                } catch (e: Exception) {
                    // Google Play not available, open app url in browser
                    val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/detail?id=${packageNmae!!}"))
                    startActivity(webIntent)
                    return true
                }
            }

        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun openSystemApp(action: String, extras: Map<String, Any>?): Boolean  {
        try {
            val intent = Intent(action)
            extras?.let {
                if (it.containsKey("uri")) {
                    intent.data = it.get("uri").toString().toUri()
                }
                if (it.containsKey("type")) {
                    intent.type = it.get("type").toString()
                }
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun callNumber(phoneNumber: String): Boolean {
        try {
            val intent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$phoneNumber")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }

            if(intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                return true;
            }
            return false;
        }catch (e: Exception) {
            e.printStackTrace()
            return false;
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // register method
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when(call.method) {
                    "openAppByPackageName" -> {
                        val packageName = call.argument<String>("packageName")
                        try {
                            val state = openAppByPackageName(packageName)
                            result.success(state)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", "Cannot open app", e.message)
                        }
                    }
                    "openSystemApp" -> {
                        val action = call.argument<String>("action")
                        val extras = call.arguments<Map<String, Any>>()
                        if(action != null) {
                            result.success(openSystemApp(action, extras))
                        } else {
                            result.error("INVALID_ARGUMENTS", "Action not provided", null)
                        }
                    }
                    "callNumber" -> {
                        val phoneNumber = call.argument<String>("phoneNumber")
                        if(phoneNumber != null) {
                            result.success(callNumber(phoneNumber))
                        }
                        else {
                            result.error("INVALID_ARGUMENTS", "Phone number not provided", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
