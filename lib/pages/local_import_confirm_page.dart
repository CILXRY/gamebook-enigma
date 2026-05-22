import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/android_package_model.dart';
import '../models/game_entry.dart';
import '../services/storage_service.dart';
import '../services/package_info_service.dart';

class LocalImportConfirmPage extends StatefulWidget {
  final List<AndroidPackageModel> packages;

  const LocalImportConfirmPage({super.key, required this.packages});

  @override
  State<LocalImportConfirmPage> createState() =>
      _LocalImportConfirmPageState();
}

enum _ImportMode { link, create }

class _PackageConfig {
  final AndroidPackageModel package;
  _ImportMode mode;
  GameEntry? linkedGame;
  TextEditingController? nameController;

  _PackageConfig({
    required this.package,
    this.mode = _ImportMode.create,
    this.linkedGame,
    this.nameController,
  });

  void dispose() {
    nameController?.dispose();
  }
}

class _LocalImportConfirmPageState extends State<LocalImportConfirmPage> {
  late List<_PackageConfig> _configs;
  List<GameEntry>? _unlinkedGames;

  @override
  void initState() {
    super.initState();
    _configs = widget.packages.map((pkg) {
      return _PackageConfig(
        package: pkg,
        nameController: TextEditingController(text: pkg.appName),
      );
    }).toList();
    _loadUnlinkedGames();
  }

  Future<void> _loadUnlinkedGames() async {
    final games = await StorageService.loadGames();
    if (!mounted) return;
    setState(() {
      _unlinkedGames =
          games.where((g) => g.linkedPackageName == null).toList();
    });
  }

  Future<void> _confirmAll() async {
    final games = await StorageService.loadGames();
    final newGames = <GameEntry>[];

    for (final config in _configs) {
      if (config.mode == _ImportMode.create) {
        final name = config.nameController?.text.trim() ?? config.package.appName;
        if (name.isEmpty) continue;
        final game = GameEntry(
          gameName: name,
          linkedPackageName: config.package.packageName,
        );
        newGames.add(game);
      } else if (config.mode == _ImportMode.link && config.linkedGame != null) {
        config.linkedGame!.linkedPackageName = config.package.packageName;
        final idx = games.indexWhere((g) => g.id == config.linkedGame!.id);
        if (idx >= 0) {
          games[idx] = config.linkedGame!;
        } else {
          games.add(config.linkedGame!);
        }
      }
    }

    games.addAll(newGames);
    await StorageService.saveGames(games);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导入 ${_configs.length} 个应用')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    for (final c in _configs) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('确认导入'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _configs.length,
        itemBuilder: (context, index) => _buildConfigTile(index),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _confirmAll,
            icon: const Icon(Icons.check),
            label: Text('确认导入 ${_configs.length} 个应用'),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigTile(int index) {
    final config = _configs[index];
    final pkg = config.package;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildIcon(pkg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.appName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(pkg.packageName,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<_ImportMode>(
                    segments: const [
                      ButtonSegment(
                          value: _ImportMode.create,
                          label: Text('创建新游戏', style: TextStyle(fontSize: 13))),
                      ButtonSegment(
                          value: _ImportMode.link,
                          label: Text('关联已有', style: TextStyle(fontSize: 13))),
                    ],
                    selected: {config.mode},
                    onSelectionChanged: (sel) {
                      setState(() => config.mode = sel.first);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (config.mode == _ImportMode.create)
              TextField(
                controller: config.nameController,
                decoration: const InputDecoration(
                  labelText: '游戏名称',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            if (config.mode == _ImportMode.link)
              _unlinkedGames == null
                  ? const Center(child: LinearProgressIndicator())
                  : _unlinkedGames!.isEmpty
                      ? const Text('没有可关联的游戏条目',
                          style: TextStyle(color: Colors.grey))
                      : DropdownButtonFormField<GameEntry>(
                          initialValue: config.linkedGame,
                          decoration: const InputDecoration(
                            labelText: '选择游戏条目',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _unlinkedGames!.map((g) {
                            return DropdownMenuItem(
                              value: g,
                              child: Text(g.gameName),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() => config.linkedGame = v);
                          },
                        ),
          ],
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
