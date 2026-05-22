package com.cilxry.gamebook

import android.app.usage.StorageStats
import android.app.usage.StorageStatsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.storage.StorageManager
import android.provider.Settings
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.util.UUID

data class InstalledPackage(
    val packageName: String,
    val appName: String,
    val versionName: String?,
    val installTime: Long,
    val isSystemApp: Boolean,
    val iconBase64: String?
)

object PackageInfoHelper {

    fun getInstalledPackages(context: Context): List<InstalledPackage> {
        val pm = context.packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val result = mutableListOf<InstalledPackage>()

        for (info in packages) {
            val isSystem = (info.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            if (isSystem) continue

            val packageName = info.packageName
            val appName = pm.getApplicationLabel(info).toString()
            val versionName = try {
                pm.getPackageInfo(packageName, 0).versionName
            } catch (_: Exception) {
                null
            }
            val installTime = try {
                pm.getPackageInfo(packageName, 0).firstInstallTime
            } catch (_: Exception) {
                0L
            }

            result.add(
                InstalledPackage(
                    packageName = packageName,
                    appName = appName,
                    versionName = versionName,
                    installTime = installTime,
                    isSystemApp = false,
                    iconBase64 = null
                )
            )
        }

        return result.sortedBy { it.appName }
    }

    fun loadAppIcon(context: Context, packageName: String): String? {
        val pm = context.packageManager
        return try {
            val info = pm.getApplicationInfo(packageName, 0)
            val drawable = info.loadIcon(pm)
            drawableToBase64(drawable)
        } catch (_: Exception) {
            null
        }
    }

    fun getPackageStorageStats(context: Context, packageName: String): Map<String, Long>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        return try {
            val ssManager = context.getSystemService(Context.STORAGE_STATS_SERVICE) as StorageStatsManager
            val uuid = StorageManager.UUID_DEFAULT
            val stats = ssManager.queryStatsForPackage(uuid, packageName, android.os.Process.myUserHandle())
            mapOf(
                "appBytes" to stats.appBytes,
                "dataBytes" to stats.dataBytes,
                "cacheBytes" to stats.cacheBytes
            )
        } catch (e: IOException) {
            null
        } catch (e: SecurityException) {
            null
        }
    }

    fun isUsagePermissionGranted(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP_MR1) return false
        return try {
            val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val stats = usm.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                now - 1000 * 60 * 60,
                now
            )
            stats.isNotEmpty()
        } catch (e: Exception) {
            false
        }
    }

    fun openUsageSettings(context: Context) {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun getPackageVersion(context: Context, packageName: String): String? {
        return try {
            context.packageManager.getPackageInfo(packageName, 0).versionName
        } catch (_: Exception) {
            null
        }
    }

    private fun drawableToBase64(drawable: Drawable): String? {
        return try {
            val bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                val bmp = Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, 64, 64)
                drawable.draw(canvas)
                bmp
            }
            val scaled = Bitmap.createScaledBitmap(bitmap, 64, 64, true)
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.PNG, 80, stream)
            Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
        } catch (_: Exception) {
            null
        }
    }
}
