package com.hzstudios.walltastic

import android.app.WallpaperManager
import android.content.Context
import android.os.Build
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONArray
import kotlin.random.Random

/**
 * Periodically sets a random wallpaper from the user's saved favorites.
 * Favorites are read from the Flutter shared preferences store.
 */
class AutoWallpaperWorker(context: Context, params: WorkerParameters) :
    Worker(context, params) {

    override fun doWork(): Result {
        val prefs = applicationContext.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
        )
        val raw = prefs.getString("flutter.walltastic.favorites.v1", null)
            ?: return Result.success()
        val favorites = try {
            JSONArray(raw)
        } catch (error: Exception) {
            return Result.success()
        }
        if (favorites.length() == 0) return Result.success()

        val url = try {
            favorites
                .getJSONObject(Random.nextInt(favorites.length()))
                .getJSONObject("src")
                .getString("original")
        } catch (error: Exception) {
            return Result.success()
        }
        val target = inputData.getString("target") ?: "both"

        return try {
            val connection = URL(url).openConnection() as HttpURLConnection
            connection.connectTimeout = 30_000
            connection.readTimeout = 30_000
            connection.inputStream.use { stream ->
                val manager = WallpaperManager.getInstance(applicationContext)
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
            Result.success()
        } catch (error: Exception) {
            if (runAttemptCount < 3) Result.retry() else Result.failure()
        }
    }
}
