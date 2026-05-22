package com.cilxry.gamebook

import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import java.util.Calendar

data class AppUsageInfo(
    val packageName: String,
    val totalTimeForegroundMs: Long,
    val lastTimeUsed: Long,
    val lastTimeVisible: Long
)

object UsageStatsHelper {

    fun getUsageStats(context: Context): List<AppUsageInfo> {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return emptyList()

        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, -30)
        val startTime = calendar.timeInMillis

        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        if (stats.isNullOrEmpty()) return emptyList()

        val merged = mutableMapOf<String, AppUsageInfo>()

        for (stat in stats) {
            val pkg = stat.packageName
            val existing = merged[pkg]
            if (existing == null) {
                merged[pkg] = AppUsageInfo(
                    packageName = pkg,
                    totalTimeForegroundMs = stat.totalTimeInForeground,
                    lastTimeUsed = stat.lastTimeUsed,
                    lastTimeVisible = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        stat.lastTimeVisible
                    } else {
                        stat.lastTimeUsed
                    }
                )
            } else {
                merged[pkg] = existing.copy(
                    totalTimeForegroundMs = existing.totalTimeForegroundMs + stat.totalTimeInForeground,
                    lastTimeUsed = maxOf(existing.lastTimeUsed, stat.lastTimeUsed),
                    lastTimeVisible = maxOf(
                        existing.lastTimeVisible,
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            stat.lastTimeVisible
                        } else {
                            stat.lastTimeUsed
                        }
                    )
                )
            }
        }

        return merged.values.toList()
    }

    fun getUsageStatsForPackage(context: Context, packageName: String): List<AppUsageInfo> {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return emptyList()

        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, -30)
        val startTime = calendar.timeInMillis

        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        return stats
            .filter { it.packageName == packageName }
            .map { stat ->
                AppUsageInfo(
                    packageName = stat.packageName,
                    totalTimeForegroundMs = stat.totalTimeInForeground,
                    lastTimeUsed = stat.lastTimeUsed,
                    lastTimeVisible = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        stat.lastTimeVisible
                    } else {
                        stat.lastTimeUsed
                    }
                )
            }
    }
}
