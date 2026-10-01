package com.hzstudios.walltastic

import android.app.WallpaperManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "walltastic/wallpaper")
            .setMethodCallHandler { call, result ->
                if (call.method != "setWallpaper") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                val target = call.argument<String>("target") ?: "both"
                if (path == null) {
                    result.error("bad_args", "Missing image path", null)
                    return@setMethodCallHandler
                }
                val mainHandler = Handler(Looper.getMainLooper())
                thread {
                    try {
                        val manager = WallpaperManager.getInstance(this)
                        FileInputStream(File(path)).use { stream ->
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                val flags = when (target) {
                                    "home" -> WallpaperManager.FLAG_SYSTEM
                                    "lock" -> WallpaperManager.FLAG_LOCK
                                    else ->
                                        WallpaperManager.FLAG_SYSTEM or
                                            WallpaperManager.FLAG_LOCK
                                }
                                manager.setStream(stream, null, true, flags)
                            } else {
                                manager.setStream(stream)
                            }
                        }
                        mainHandler.post { result.success(true) }
                    } catch (error: Exception) {
                        mainHandler.post {
                            result.error("set_failed", error.message, null)
                        }
                    }
                }
            }
    }
}
