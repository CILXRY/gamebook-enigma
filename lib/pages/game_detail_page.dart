import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/preset_tags.dart';
import '../models/game_atom_model.dart';
import '../models/game_entry.dart';
import '../models/mihoyo/hoyo_game_profile.dart';
import '../models/mihoyo/character.dart';
import '../services/mihoyo/game_data_service.dart';
import '../services/mihoyo/mihoyo_api_client.dart';
import '../services/package_info_service.dart';
import '../services/usage_stats_service.dart';
import '../services/local_game_sync_service.dart';
import '../widgets/resources_editor.dart';

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _recText(int? v) {
  return switch (v) {
    3 => '👍 推荐',
    2 => '🙂 还行',
    1 => '👎 不推荐',
    _ => '-',
  };
}

String _spendingText(int? v) {
  return switch (v) {
    0 => '🆓 零氪',
    1 => '☕ 微氪',
    2 => '💰 中氪',
    3 => '🐳 重氪',
    _ => '-',
  };
}

String _barrierText(int? v) {
  return switch (v) {
    0 => '随时可回',
    1 => '需要适应一阵',
    2 => '基本回不来了',
    _ => '-',
  };
}

class GameDetailPage extends StatefulWidget {
  final GameEntry game;

  const GameDetailPage({super.key, required this.game});

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  late GameEntry _game;
  bool _editing = false;

  late TextEditingController _nameController;
  late TextEditingController _charNameController;
  late TextEditingController _levelController;
  late TextEditingController _serverController;
  late TextEditingController _playHoursController;
  late TextEditingController _progressController;
  late TextEditingController _notesController;
  DateTime? _lastPlayed;
  bool _isRetired = false;

  List<String> _tags = [];
  int? _recommendation;
  int? _spending;
  int? _returnBarrier;
  late TextEditingController _tagInputController;

  String? _systemUsageText;
  bool _isSyncing = false;
  String? _pkgIcon;
  String? _pkgVersion;
  Map<String, int>? _pkgStorage;

  @override
  void initState() {
    super.initState();
    _game = widget.game;
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _game.gameName);
    _charNameController = TextEditingController(text: _game.characterName ?? '');
    _levelController = TextEditingController(text: _game.level?.toString() ?? '');
    _serverController = TextEditingController(text: _game.server ?? '');
    _playHoursController = TextEditingController(text: _game.gamePlayedSeconds > 0 ? (_game.gamePlayedSeconds / 3600).toStringAsFixed(1) : '');
    _progressController = TextEditingController(text: _game.progress ?? '');
    _notesController = TextEditingController(text: _game.notes ?? '');
    _lastPlayed = _game.gameLastLaunched;
    _isRetired = _game.isRetired;
    _tags = List.from(_game.tags);
    _recommendation = _game.recommendation;
    _spending = _game.spending;
    _returnBarrier = _game.returnBarrier;
    _tagInputController = TextEditingController();
    _loadSystemData();
  }

  Future<void> _loadSystemData() async {
    if (_game.linkedPackageName == null) return;
    final results = await Future.wait([
      UsageStatsService.getUsageStatsForPackage(_game.linkedPackageName!),
      PackageInfoService.getAppIcon(_game.linkedPackageName!),
      PackageInfoService.getPackageStorageSize(_game.linkedPackageName!),
      PackageInfoService.getPackageVersion(_game.linkedPackageName!),
    ]);
    if (!mounted) return;
    final statsList = results[0] as List;
    final icon = (results[1] as String?) ?? '';
    final storage = results[2] as Map<String, int>?;
    final version = (results[3] as String?) ?? '';

    double totalMs = 0;
    int latestUsed = 0;
    for (final s in statsList.cast()) {
      totalMs += s.totalTimeForegroundMs;
      if (s.lastTimeUsed > latestUsed) latestUsed = s.lastTimeUsed;
    }
    setState(() {
      _pkgIcon = icon.isNotEmpty ? icon : null;
      _pkgStorage = storage;
      _pkgVersion = version.isNotEmpty ? version : null;
      if (totalMs > 0 || latestUsed > 0) {
        _systemUsageText = [
          if (totalMs > 0) '系统统计时长: ${(totalMs / (1000 * 60 * 60)).toStringAsFixed(1)} 小时',
          if (latestUsed > 0)
            '最近使用: ${_formatDate(DateTime.fromMillisecondsSinceEpoch(latestUsed))}',
        ].join('\n');
      }
    });
  }

  Future<void> _syncFromSystem() async {
    if (_game.linkedPackageName == null) return;
    setState(() => _isSyncing = true);
    try {
      await LocalGameSyncService.syncSingle(_game);
      await _loadSystemData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已从系统同步数据')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e')),
        );
      }
    }
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _charNameController.dispose();
    _levelController.dispose();
    _serverController.dispose();
    _playHoursController.dispose();
    _progressController.dispose();
    _notesController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      if (_editing) {
        _saveChanges();
      }
      _editing = !_editing;
    });
  }

  void _saveChanges() {
    _game.gameName = _nameController.text.trim().isEmpty ? _game.gameName : _nameController.text.trim();
    _game.characterName = _charNameController.text.trim().isEmpty ? null : _charNameController.text.trim();
    _game.level = int.tryParse(_levelController.text.trim());
    _game.server = _serverController.text.trim().isEmpty ? null : _serverController.text.trim();
    _game.gamePlayedSeconds = GameAtomModel.playHoursToSeconds(_playHoursController.text.trim());
    _game.gameLastLaunched = _lastPlayed;
    _game.isRetired = _isRetired;
    _game.progress = _progressController.text.trim().isEmpty ? null : _progressController.text.trim();
    _game.notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    _game.tags = List.from(_tags);
    _game.recommendation = _recommendation;
    _game.spending = _spending;
    _game.returnBarrier = _returnBarrier;
  }

  void _addCustomTag() {
    final t = _tagInputController.text.trim();
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() {
      _tags.add(t);
      _tagInputController.clear();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPlayed ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _lastPlayed = picked;
      });
    }
  }

  void _deleteGame() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除游戏'),
        content: Text('确定要删除「${_game.gameName}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _editing) {
          _toggleEdit();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editing ? '编辑游戏' : _game.gameName),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: Icon(_editing ? Icons.check : Icons.edit),
              tooltip: _editing ? '保存' : '编辑',
              onPressed: _toggleEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteGame,
            ),
          ],
        ),
        body: _editing ? _buildEditMode() : _buildViewMode(),
      ),
    );
  }

  // ── view mode ─────────────────────────────────────────────────────

  Widget _buildViewMode() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_game.isRetired) _retiredBanner(),

        _sectionLabel('基本信息'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('游戏名称', _game.gameName),
                const Divider(height: 20),
                _infoRow('角色名', _game.characterName ?? '-'),
                const Divider(height: 20),
                _infoRow('区服', _game.server ?? '-'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        _sectionLabel('账号数据'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _infoRow('等级', _game.level?.toString() ?? '-')),
                    Expanded(child: _infoRow('游戏时长', _game.gamePlayedSeconds > 0 ? '${(_game.gamePlayedSeconds / 3600).toStringAsFixed(1)} 小时' : '-')),
                  ],
                ),
                const Divider(height: 20),
                const Text('资源', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                ResourcesEditor(game: _game, enabled: false),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        if (_game.hoyoProfile != null)
          ..._buildHoyoSection(_game.hoyoProfile!),
        if (_game.hoyoProfile == null)
          _buildBindHoyoCard(),
        const SizedBox(height: 20),
        _sectionLabel('主观评价'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('推荐度', _recText(_game.recommendation)),
                const Divider(height: 20),
                _infoRow('氪金程度', _spendingText(_game.spending)),
                const Divider(height: 20),
                _infoRow('回流阻力', _barrierText(_game.returnBarrier)),
                if (_game.tags.isNotEmpty) ...[
                  const Divider(height: 20),
                  const Text('标签', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _game.tags.map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        _sectionLabel('游戏状态'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('上次游玩', _game.gameLastLaunched != null ? _formatDate(_game.gameLastLaunched!) : '-'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        if (_game.linkedPackageName != null) ...[
          Row(
            children: [
              Expanded(child: _sectionLabel('系统数据')),
              IconButton(
                icon: _isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, size: 20),
                tooltip: '从系统同步',
                onPressed: _isSyncing ? null : _syncFromSystem,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_pkgIcon != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(_pkgIcon!),
                              width: 32,
                              height: 32,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      Expanded(child: _infoRow('关联包名', _game.linkedPackageName!)),
                    ],
                  ),
                  if (_pkgVersion != null) ...[
                    const Divider(height: 20),
                    _infoRow('版本', _pkgVersion!),
                  ],
                  if (_pkgStorage != null) ...[
                    const Divider(height: 20),
                    _infoRow('存储占用',
                        PackageInfoService.formatBytes(
                          (_pkgStorage!['appBytes'] ?? 0) +
                              (_pkgStorage!['dataBytes'] ?? 0) +
                              (_pkgStorage!['cacheBytes'] ?? 0),
                        )),
                  ],
                  if (_systemUsageText != null) ...[
                    const Divider(height: 20),
                    Text(_systemUsageText!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        _sectionLabel('其他'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('当前进度', _game.progress ?? '-'),
                if (_game.progress != null) const Divider(height: 20),
                _infoRow('备注', _game.notes ?? '-'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _retiredBanner() {
    return Card(
      color: Colors.grey[200],
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.bedtime, color: Colors.grey),
            SizedBox(width: 8),
            Text('已退坑', style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  // ── hoyo section ───────────────────────────────────────────────────

  List<Widget> _buildHoyoSection(HoyoGameProfile profile) {
    return [
      Row(
        children: [
          Expanded(child: _sectionLabel('米游社档案')),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: '刷新数据',
            onPressed: () => _syncHoyoData(),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('UID', profile.gameUid),
              const Divider(height: 20),
              _infoRow('昵称', profile.gameNickname),
              const Divider(height: 20),
              _infoRow('等级', '${profile.gameLevel} 级'),
              const Divider(height: 20),
              _infoRow('服务器', profile.gameServer),
              const Divider(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _statItem('活跃天数', '${profile.collections.activeDays}'),
                  _statItem('角色收集', '${profile.collections.avatarsCollected}'),
                  _statItem('成就收集', '${profile.collections.achievementsCollected}'),
                  _statItem('宝箱收集', '${profile.collections.chestCollected}'),
                ],
              ),
              if (profile.avatarList.isNotEmpty) ...[
                const Divider(height: 24),
                const Text('角色列表',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: profile.avatarList.length,
                    itemBuilder: (context, index) =>
                        _avatarCard(profile.avatarList[index]),
                  ),
                ),
              ],
              const Divider(height: 20),
              _infoRow('数据时间', _formatDate(profile.fetchedAt)),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _avatarCard(Character character) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  character.icon,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[200],
                    child: const Icon(Icons.person,
                        size: 32, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                character.name,
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                'Lv.${character.level}',
                style: TextStyle(fontSize: 9, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncHoyoData({String? gameBiz, String? uid}) async {
    final biz = gameBiz ?? _game.hoyoProfile?.gameBiz;
    final roleId = uid ?? _game.hoyoProfile?.gameUid;

    if (biz == null || roleId == null) {
      _showBindHoyoDialog();
      return;
    }

    try {
      final service = GameDataService();
      final profile = await service.fetchGameProfile(
        gameBiz: biz,
        uid: roleId,
      );
      if (!mounted) return;
      setState(() {
        _game.hoyoProfile = profile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数据同步成功')),
      );
    } on MihoyoApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败 ($e)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e')),
        );
      }
    }
  }

  Future<void> _showBindHoyoDialog() async {
    String? selectedBiz;

    final name = _game.gameName;
    if (name.contains('星穹铁道') || name.contains('崩铁')) {
      selectedBiz = 'hkrpg_cn';
    } else if (name.contains('原神')) {
      selectedBiz = 'hk4e_cn';
    } else if (name.contains('绝区零')) {
      selectedBiz = 'nap_cn';
    }

    final uidController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('绑定米游社数据'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedBiz,
                decoration: const InputDecoration(
                  labelText: '游戏',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'hkrpg_cn',
                      child: Text('崩坏：星穹铁道')),
                  DropdownMenuItem(
                      value: 'hk4e_cn', child: Text('原神')),
                  DropdownMenuItem(
                      value: 'nap_cn', child: Text('绝区零')),
                ],
                onChanged: (v) =>
                    setDialogState(() => selectedBiz = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: uidController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '游戏 UID',
                  border: OutlineInputBorder(),
                  hintText: '输入你的游戏 UID',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedBiz == null ||
                    uidController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx, {
                  'gameBiz': selectedBiz!,
                  'uid': uidController.text.trim(),
                });
              },
              child: const Text('同步'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      _syncHoyoData(
          gameBiz: result['gameBiz']!, uid: result['uid']!);
    }
  }

  Widget _buildBindHoyoCard() {
    return Card(
      child: InkWell(
        onTap: _showBindHoyoDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.link,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text('绑定米游社数据',
                  style: TextStyle(fontSize: 14)),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ── edit mode ─────────────────────────────────────────────────────

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('基本信息'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '游戏名称', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _charNameController,
            decoration: const InputDecoration(labelText: '角色名 / 游戏内ID', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serverController,
            decoration: const InputDecoration(labelText: '区服', border: OutlineInputBorder()),
          ),

          const SizedBox(height: 24),
          _sectionLabel('账号数据'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _levelController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '等级', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _playHoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '游戏时长 (小时)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('资源', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          ResourcesEditor(game: _game, enabled: true),

          const SizedBox(height: 24),
          _sectionLabel('主观评价'),
          const SizedBox(height: 8),
          _buildTagEditor(),
          const SizedBox(height: 20),
          _buildChoiceField('推荐度', {
            3: '👍 推荐',
            2: '🙂 还行',
            1: '👎 不推荐',
          }, _recommendation, (v) => setState(() => _recommendation = v)),
          const SizedBox(height: 16),
          _buildChoiceField('氪金程度', {
            0: '🆓 零氪',
            1: '☕ 微氪',
            2: '💰 中氪',
            3: '🐳 重氪',
          }, _spending, (v) => setState(() => _spending = v)),
          const SizedBox(height: 16),
          _buildChoiceField('回流阻力', {
            0: '随时可回',
            1: '需要适应一阵',
            2: '基本回不来了',
          }, _returnBarrier, (v) => setState(() => _returnBarrier = v)),

          const SizedBox(height: 24),
          _sectionLabel('游戏状态'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('上次游玩: '),
              TextButton(
                onPressed: _pickDate,
                child: Text(_lastPlayed != null ? _formatDate(_lastPlayed!) : '点击选择日期'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('已退坑'),
            subtitle: Text(_isRetired ? '已标记为退坑' : '还在玩'),
            value: _isRetired,
            onChanged: (v) => setState(() => _isRetired = v),
          ),

          const SizedBox(height: 24),
          _sectionLabel('其他'),
          const SizedBox(height: 8),
          TextField(
            controller: _progressController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: '当前进度', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '备注', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildTagEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('标签', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in presetTags)
              FilterChip(
                label: Text(t, style: const TextStyle(fontSize: 13)),
                selected: _tags.contains(t),
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      _tags.add(t);
                    } else {
                      _tags.remove(t);
                    }
                  });
                },
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            for (final t in _tags.where((t) => !presetTags.contains(t)))
              InputChip(
                label: Text(t, style: const TextStyle(fontSize: 13)),
                onDeleted: () => setState(() => _tags.remove(t)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagInputController,
                decoration: const InputDecoration(
                  hintText: '自定义标签...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _addCustomTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addCustomTag,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceField(
      String label, Map<int, String> options, int? value, ValueChanged<int?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.entries.map((e) {
            return ChoiceChip(
              label: Text(e.value, style: const TextStyle(fontSize: 13)),
              selected: value == e.key,
              onSelected: (sel) => onChanged(sel ? e.key : null),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── shared helpers ────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
