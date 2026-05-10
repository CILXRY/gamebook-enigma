import 'package:flutter/material.dart';
import '../models/game_entry.dart';
import '../services/storage_service.dart';
import 'game_detail_page.dart';

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

  void _addGame() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加游戏'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入游戏名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              setState(() {
                _games.add(GameEntry(name: name));
              });
              _saveGames();
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
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
        content: Text('确定要删除「${game.name}」吗？此操作不可撤销。'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏本子'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                return _GameCard(
                  game: game,
                  onTap: () => _openDetail(game),
                  onLongPress: () => _deleteGame(game),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGame,
        icon: const Icon(Icons.add),
        label: const Text('添加游戏'),
      ),
    );
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
                            game.name,
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
                    Text(
                      [
                        if (game.server != null) game.server!,
                        if (game.lastPlayed != null)
                          '上次: ${_formatDate(game.lastPlayed!)}',
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
