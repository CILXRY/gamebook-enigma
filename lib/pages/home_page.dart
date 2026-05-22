import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/game_entry.dart';
import '../services/storage_service.dart';
import '../services/package_info_service.dart';
import 'add_game_page.dart';
import 'game_detail_page.dart';
import 'import_hoyo_page.dart';
import 'local_games_page.dart';
import 'settings_page.dart';

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<GameEntry> _games = [];

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final games = await StorageService.loadGames();
    setState(() {
      _games = games;
    });
  }

  Future<void> _saveGames() async {
    await StorageService.saveGames(_games);
  }

  Future<void> _addGame() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('从米游社导入'),
              subtitle: const Text('自动获取游戏账号信息'),
              onTap: () => Navigator.pop(ctx, 'import'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('自定义游戏'),
              subtitle: const Text('手动填写所有字段'),
              onTap: () => Navigator.pop(ctx, 'custom'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('从本地应用导入'),
              subtitle: const Text('扫描已安装游戏并关联'),
              onTap: () => Navigator.pop(ctx, 'local'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'import') {
      final game = await Navigator.push<GameEntry>(
        context,
        MaterialPageRoute(builder: (_) => const ImportHoyoPage()),
      );
      if (game != null) {
        setState(() => _games.add(game));
        _saveGames();
      }
    } else if (choice == 'local') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LocalGamesPage()),
      ).then((_) => _loadGames());
    } else {
      final game = await Navigator.push<GameEntry>(
        context,
        MaterialPageRoute(builder: (_) => const AddGamePage()),
      );
      if (game != null) {
        setState(() => _games.add(game));
        _saveGames();
      }
    }
  }

  Future<void> _openDetail(GameEntry game) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailPage(game: game),
      ),
    );
    if (deleted == true) {
      setState(() {
        _games.removeWhere((g) => g.id == game.id);
      });
      _saveGames();
    } else {
      _saveGames();
      setState(() {});
    }
  }

  void _deleteGame(GameEntry game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除游戏'),
        content: Text('确定要删除「${game.gameName}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _games.removeWhere((g) => g.id == game.id);
              });
              _saveGames();
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final total = _games.length;
    final totalSeconds = _games.fold<int>(0, (s, g) => s + g.gamePlayedSeconds);
    final active = _games.where((g) => !g.isRetired).length;
    final retired = _games.where((g) => g.isRetired).length;

    final totalHours = (totalSeconds / 3600).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _overviewItem('游戏总数', '$total'),
            _overviewItem('总时长', '${totalHours}h'),
            _overviewItem('正在玩', '$active'),
            _overviewItem('已退坑', '$retired'),
          ],
        ),
      ),
    );
  }

  Widget _overviewItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏本子'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: _games.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_esports, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('还没有记录任何游戏',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('点击右下角按钮添加吧',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildOverviewCard(),
                ..._games.map((game) => _GameCard(
                      game: game,
                      onTap: () => _openDetail(game),
                      onLongPress: () => _deleteGame(game),
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGame,
        icon: const Icon(Icons.add),
        label: const Text('添加游戏'),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final String packageName;

  const _AppIcon({required this.packageName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: PackageInfoService.getAppIcon(packageName),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          try {
            final bytes = base64Decode(snapshot.data!);
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(bytes, width: 36, height: 36,
                  errorBuilder: (_, _, _) => _fallback()),
            );
          } catch (_) {
            return _fallback();
          }
        }
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    return const Icon(Icons.sports_esports, size: 36, color: Colors.grey);
  }
}

class _GameCard extends StatelessWidget {
  final GameEntry game;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GameCard({
    required this.game,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (game.linkedPackageName != null)
                _AppIcon(packageName: game.linkedPackageName!)
              else
                Icon(
                  game.isRetired ? Icons.bedtime : Icons.sports_esports,
                  color: game.isRetired
                      ? Colors.grey
                      : Theme.of(context).colorScheme.primary,
                  size: 36,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            game.gameName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: game.isRetired ? Colors.grey : null,
                              decoration: game.isRetired
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (game.level != null) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('Lv.${game.level}',
                                style: const TextStyle(fontSize: 12)),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                        if (game.isRetired)
                          const Chip(
                            label: Text('退坑',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey)),
                            backgroundColor: Colors.grey,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (game.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: game.tags.take(3).map((t) => Chip(
                              label: Text(t, style: const TextStyle(fontSize: 11)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                            )).toList(),
                      ),
                    Text(
                      [
                        if (game.server != null) game.server!,
                        if (game.gamePlayedSeconds > 0)
                          '${(game.gamePlayedSeconds / 3600).toStringAsFixed(1)} 小时',
                        if (game.gameLastLaunched != null)
                          '上次: ${_formatDate(game.gameLastLaunched!)}',
                        if (game.characterName != null) game.characterName!,
                      ].join('  ·  '),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
