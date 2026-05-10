import 'package:flutter/material.dart';
import '../constants/preset_tags.dart';
import '../models/game_entry.dart';
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

  @override
  void initState() {
    super.initState();
    _game = widget.game;
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _game.name);
    _charNameController = TextEditingController(text: _game.characterName ?? '');
    _levelController = TextEditingController(text: _game.level?.toString() ?? '');
    _serverController = TextEditingController(text: _game.server ?? '');
    _playHoursController = TextEditingController(text: _game.totalPlayHours?.toString() ?? '');
    _progressController = TextEditingController(text: _game.progress ?? '');
    _notesController = TextEditingController(text: _game.notes ?? '');
    _lastPlayed = _game.lastPlayed;
    _isRetired = _game.isRetired;
    _tags = List.from(_game.tags);
    _recommendation = _game.recommendation;
    _spending = _game.spending;
    _returnBarrier = _game.returnBarrier;
    _tagInputController = TextEditingController();
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
    _game.name = _nameController.text.trim().isEmpty ? _game.name : _nameController.text.trim();
    _game.characterName = _charNameController.text.trim().isEmpty ? null : _charNameController.text.trim();
    _game.level = int.tryParse(_levelController.text.trim());
    _game.server = _serverController.text.trim().isEmpty ? null : _serverController.text.trim();
    _game.totalPlayHours = double.tryParse(_playHoursController.text.trim());
    _game.lastPlayed = _lastPlayed;
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
        content: Text('确定要删除「${_game.name}」吗？此操作不可撤销。'),
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
          title: Text(_editing ? '编辑游戏' : _game.name),
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
                _infoRow('游戏名称', _game.name),
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
                    Expanded(child: _infoRow('游戏时长', _game.totalPlayHours != null ? '${_game.totalPlayHours} 小时' : '-')),
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
                _infoRow('上次游玩', _game.lastPlayed != null ? _formatDate(_game.lastPlayed!) : '-'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
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
