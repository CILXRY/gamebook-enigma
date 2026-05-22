package com.cilxry.gamebook

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val packageChannel = "gamebook/packages"
    private val usageStatsChannel = "gamebook/usage_stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val mainHandler = Handler(Looper.getMainLooper())

        MethodChannel(messenger, packageChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledPackages" -> {
                    Thread {
                        try {
                            val packages = PackageInfoHelper.getInstalledPackages(this@MainActivity)
                            val list = packages.map { pkg ->
                                mapOf(
                                    "packageName" to pkg.packageName,
                                    "appName" to pkg.appName,
                                    "versionName" to (pkg.versionName ?: ""),
                                    "installTime" to pkg.installTime,
                                    "isSystemApp" to pkg.isSystemApp,
                                    "iconBase64" to (pkg.iconBase64 ?: "")
                                )
                            }
                            mainHandler.post { result.success(list) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("PACKAGE_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    Thread {
                        try {
                            val icon = PackageInfoHelper.loadAppIcon(this@MainActivity, packageName)
                            mainHandler.post { result.success(icon ?: "") }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("ICON_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "getPackageStorageSize" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    Thread {
                        try {
                            val stats = PackageInfoHelper.getPackageStorageStats(this@MainActivity, packageName)
                            mainHandler.post { result.success(stats) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("STORAGE_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "isUsagePermissionGranted" -> {
                    try {
                        result.success(PackageInfoHelper.isUsagePermissionGranted(this@MainActivity))
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "openUsageSettings" -> {
                    try {
                        PackageInfoHelper.openUsageSettings(this@MainActivity)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }
                "getPackageVersion" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    try {
                        result.success(PackageInfoHelper.getPackageVersion(this@MainActivity, packageName) ?: "")
                    } catch (e: Exception) {
                        result.success("")
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, usageStatsChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAllUsageStats" -> {
                    Thread {
                        try {
                            val stats = UsageStatsHelper.getUsageStats(this@MainActivity)
                            val list = stats.map { s ->
                                mapOf(
                                    "packageName" to s.packageName,
                                    "totalTimeForegroundMs" to s.totalTimeForegroundMs,
                                    "lastTimeUsed" to s.lastTimeUsed,
                                    "lastTimeVisible" to s.lastTimeVisible
                                )
                            }
                            mainHandler.post { result.success(list) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("USAGE_STATS_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "getUsageStatsForPackage" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    Thread {
                        try {
                            val stats = UsageStatsHelper.getUsageStatsForPackage(this@MainActivity, packageName)
                            val list = stats.map { s ->
                                mapOf(
                                    "packageName" to s.packageName,
                                    "totalTimeForegroundMs" to s.totalTimeForegroundMs,
                                    "lastTimeUsed" to s.lastTimeUsed,
                                    "lastTimeVisible" to s.lastTimeVisible
                                )
                            }
                            mainHandler.post { result.success(list) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("USAGE_STATS_ERROR", e.message, null) }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }
}
