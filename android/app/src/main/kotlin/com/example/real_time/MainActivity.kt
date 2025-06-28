package com.example.real_time

import android.content.Intent
import android.net.Uri
import android.util.Log
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
                    else -> result.notImplemented()
                }
            }
    }
}
