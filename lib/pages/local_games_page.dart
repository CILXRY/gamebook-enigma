import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/android_package_model.dart';
import '../models/app_usage_stats.dart';
import '../models/game_entry.dart';
import '../services/package_info_service.dart';
import '../services/usage_stats_service.dart';
import '../services/storage_service.dart';
import 'game_detail_page.dart';

class LocalGamesPage extends StatefulWidget {
  const LocalGamesPage({super.key});

  @override
  State<LocalGamesPage> createState() => _LocalGamesPageState();
}

class _LocalGamesPageState extends State<LocalGamesPage> {
  List<AndroidPackageModel> _packages = [];
  List<AppUsageStats> _usageStats = [];
  List<GameEntry> _linkedGames = [];
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      PackageInfoService.getInstalledPackages(),
      UsageStatsService.getAllUsageStats(),
      StorageService.loadGames(),
    ]);
    if (!mounted) return;
    setState(() {
      _packages = results[0] as List<AndroidPackageModel>;
      _usageStats = results[1] as List<AppUsageStats>;
      _linkedGames = (results[2] as List<GameEntry>)
          .where((g) => g.linkedPackageName != null)
          .toList();
      _loading = false;
    });
  }

  Future<void> _refreshLinked() async {
    final games = await StorageService.loadGames();
    if (!mounted) return;
    setState(() {
      _linkedGames = games.where((g) => g.linkedPackageName != null).toList();
    });
  }

  Future<void> _refreshStats() async {
    final stats = await UsageStatsService.getAllUsageStats();
    if (!mounted) return;
    setState(() => _usageStats = stats);
  }

  AppUsageStats? _statsFor(String pkg) {
    try {
      return _usageStats.firstWhere((s) => s.packageName == pkg);
    } catch (_) {
      return null;
    }
  }

  GameEntry? _gameFor(String pkg) {
    try {
      return _linkedGames.firstWhere((g) => g.linkedPackageName == pkg);
    } catch (_) {
      return null;
    }
  }

  List<AndroidPackageModel> get _filtered {
    if (_searchQuery.isEmpty) return _packages;
    final q = _searchQuery.toLowerCase();
    return _packages.where((p) =>
        p.appName.toLowerCase().contains(q) ||
        p.packageName.toLowerCase().contains(q)).toList();
  }

  List<MapEntry<AndroidPackageModel, AppUsageStats>> get _topByUsage {
    final entries = <MapEntry<AndroidPackageModel, AppUsageStats>>[];
    for (final pkg in _packages) {
      final stats = _statsFor(pkg.packageName);
      if (stats != null && stats.totalTimeForegroundMs > 0) {
        entries.add(MapEntry(pkg, stats));
      }
    }
    entries.sort((a, b) =>
        b.value.totalTimeForegroundMs.compareTo(a.value.totalTimeForegroundMs));
    return entries.take(5).toList();
  }

  Future<void> _linkPackage(AndroidPackageModel pkg) async {
    if (_gameFor(pkg.packageName) != null) return;

    if (_linkedGames.isNotEmpty) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.link),
                title: Text('关联到已有游戏: ${pkg.appName}'),
                subtitle: const Text('选择一个游戏条目绑定此本地应用'),
                onTap: () => Navigator.pop(ctx, 'link'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add),
                title: Text('创建新游戏: ${pkg.appName}'),
                subtitle: const Text('创建新的游戏条目并关联此应用'),
                onTap: () => Navigator.pop(ctx, 'create'),
              ),
            ],
          ),
        ),
      );
      if (choice == null) return;

      GameEntry? game;
      if (choice == 'link') {
        final candidates = await StorageService.loadGames();
        final unlinked =
            candidates.where((g) => g.linkedPackageName == null).toList();
        if (unlinked.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('没有可关联的游戏条目')),
            );
          }
          return;
        }
        game = await showDialog<GameEntry>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('选择游戏条目'),
            children: unlinked.map((g) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, g),
                  child: Text(g.gameName),
                )).toList(),
          ),
        );
        if (game != null) {
          game.linkedPackageName = pkg.packageName;
        }
      } else {
        game = GameEntry(
          gameName: pkg.appName,
          linkedPackageName: pkg.packageName,
        );
      }

      if (game != null) {
        final games = await StorageService.loadGames();
        final idx = games.indexWhere((g) => g.id == game!.id);
        if (idx >= 0) {
          games[idx] = game;
        } else {
          games.add(game);
        }
        await StorageService.saveGames(games);
        await _refreshLinked();
        await _syncSingleNoReload(game.linkedPackageName!);
      }
    } else {
      final game = GameEntry(
        gameName: pkg.appName,
        linkedPackageName: pkg.packageName,
      );
      final games = await StorageService.loadGames();
      games.add(game);
      await StorageService.saveGames(games);
      await _refreshLinked();
      await _syncSingleNoReload(game.linkedPackageName!);
    }
  }

  Future<void> _unlinkPackage(GameEntry game) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解除关联'),
        content: Text('确定要解除「${game.gameName}」与本地应用的关联吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => game.linkedPackageName = null);
    final games = await StorageService.loadGames();
    final idx = games.indexWhere((g) => g.id == game.id);
    if (idx >= 0) {
      games[idx] = game;
      await StorageService.saveGames(games);
    }
    await _refreshLinked();
  }

  Future<void> _syncSingleNoReload(String packageName) async {
    final stats = _statsFor(packageName);
    if (stats == null) return;

    final game = _gameFor(packageName);
    if (game == null) return;

    if (stats.totalTimeForegroundMs > 0) {
      game.gamePlayedSeconds = stats.totalTimeSeconds;
    }
    if (stats.lastTimeUsed > 0) {
      game.gameLastLaunched =
          DateTime.fromMillisecondsSinceEpoch(stats.lastTimeUsed);
    }

    final games = await StorageService.loadGames();
    final idx = games.indexWhere((g) => g.id == game.id);
    if (idx >= 0) {
      games[idx] = game;
      await StorageService.saveGames(games);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${game.gameName}」数据已同步')),
      );
    }
  }

  Future<void> _syncAll() async {
    for (final game in _linkedGames) {
      final stats = _statsFor(game.linkedPackageName!);
      if (stats == null) continue;
      if (stats.totalTimeForegroundMs > 0) {
        game.gamePlayedSeconds = stats.totalTimeSeconds;
      }
      if (stats.lastTimeUsed > 0) {
        game.gameLastLaunched =
            DateTime.fromMillisecondsSinceEpoch(stats.lastTimeUsed);
      }
    }
    final allGames = await StorageService.loadGames();
    for (final game in _linkedGames) {
      final idx = allGames.indexWhere((g) => g.id == game.id);
      if (idx >= 0) {
        allGames[idx] = game;
      }
    }
    await StorageService.saveGames(allGames);
    await _refreshStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已同步 ${_linkedGames.length} 个游戏')),
      );
    }
  }

  void _openGameDetail(GameEntry game) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => GameDetailPage(game: game)),
    ).then((_) => _refreshLinked());
  }

  String _formatDuration(int ms) {
    if (ms == 0) return '-';
    final hours = ms / (1000 * 60 * 60);
    if (hours < 1) {
      final minutes = ms / (1000 * 60);
      return '${minutes.toStringAsFixed(0)} 分钟';
    }
    return '${hours.toStringAsFixed(1)} 小时';
  }

  String _formatTimestamp(int ms) {
    if (ms == 0) return '-';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地游戏'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _loadAll,
          ),
          if (_linkedGames.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: '一键同步',
              onPressed: _syncAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在扫描已安装应用...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '搜索应用...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                if (_searchQuery.isEmpty && _topByUsage.isNotEmpty)
                  _buildUsageChart(),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('没有找到应用'))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final pkg = _filtered[index];
                            final stats = _statsFor(pkg.packageName);
                            final linked = _gameFor(pkg.packageName);
                            return _buildPackageTile(pkg, stats, linked);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildUsageChart() {
    final data = _topByUsage;
    final maxMs = data.map((e) => e.value.totalTimeForegroundMs).toList();
    final maxY = maxMs.isEmpty
        ? 1.0
        : maxMs.reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 200,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('使用时长 Top 5',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY * 1.1,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final entry = data[groupIndex];
                          return BarTooltipItem(
                            '${entry.key.appName}\n${_formatDuration(entry.value.totalTimeForegroundMs)}',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= data.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                data[idx].key.appName,
                                style: const TextStyle(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final hours = value / (1000 * 60 * 60);
                            return Text(
                              hours >= 1
                                  ? '${hours.toInt()}h'
                                  : '${(value / (1000 * 60)).toInt()}m',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(data.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i]
                                .value
                                .totalTimeForegroundMs
                                .toDouble(),
                            color: Theme.of(context).colorScheme.primary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageTile(
      AndroidPackageModel pkg, AppUsageStats? stats, GameEntry? linked) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          if (linked != null) {
            _openGameDetail(linked);
          } else {
            _linkPackage(pkg);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildIcon(pkg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pkg.appName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (linked != null) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.link,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pkg.packageName,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (pkg.versionName.isNotEmpty) ...[
                          Text(pkg.versionName,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[450])),
                          const SizedBox(width: 8),
                        ],
                        _StorageSizeWidget(packageName: pkg.packageName),
                      ],
                    ),
                    if (stats != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(_formatDuration(stats.totalTimeForegroundMs),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(_formatTimestamp(stats.lastTimeUsed),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (linked != null)
                IconButton(
                  icon: const Icon(Icons.sync, size: 20),
                  tooltip: '同步数据',
                  onPressed: () => _syncSingleNoReload(pkg.packageName),
                ),
              if (linked != null)
                IconButton(
                  icon:
                      Icon(Icons.link_off, size: 20, color: Colors.red[300]),
                  tooltip: '解除关联',
                  onPressed: () => _unlinkPackage(linked),
                ),
              if (linked == null)
                TextButton(
                  onPressed: () => _linkPackage(pkg),
                  child: const Text('关联', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(AndroidPackageModel pkg) {
    return FutureBuilder<String>(
      future: PackageInfoService.getAppIcon(pkg.packageName),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          try {
            final bytes = base64Decode(snapshot.data!);
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                bytes,
                width: 40,
                height: 40,
                errorBuilder: (_, _, _) => _defaultIcon(),
              ),
            );
          } catch (_) {
            return _defaultIcon();
          }
        }
        return _defaultIcon();
      },
    );
  }

  Widget _defaultIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.android, color: Colors.grey[500], size: 24),
    );
  }
}

class _StorageSizeWidget extends StatelessWidget {
  final String packageName;

  const _StorageSizeWidget({required this.packageName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>?>(
      future: PackageInfoService.getPackageStorageSize(packageName),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final total = (snapshot.data!['appBytes'] ?? 0) +
            (snapshot.data!['dataBytes'] ?? 0) +
            (snapshot.data!['cacheBytes'] ?? 0);
        if (total == 0) return const SizedBox.shrink();
        return Text(
          PackageInfoService.formatBytes(total),
          style: TextStyle(fontSize: 11, color: Colors.grey[450]),
        );
      },
    );
  }
}
