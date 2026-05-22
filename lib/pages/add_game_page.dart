import 'package:flutter/material.dart';
import '../constants/preset_tags.dart';
import '../models/android_package_model.dart';
import '../models/game_atom_model.dart';
import '../models/game_entry.dart';
import '../services/package_info_service.dart';
import '../widgets/resources_editor.dart';

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class AddGamePage extends StatefulWidget {
  const AddGamePage({super.key});

  @override
  State<AddGamePage> createState() => _AddGamePageState();
}

class _AddGamePageState extends State<AddGamePage> {
  final _nameController = TextEditingController();
  final _charNameController = TextEditingController();
  final _serverController = TextEditingController();
  final _levelController = TextEditingController();
  final _playHoursController = TextEditingController();
  final _progressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _lastPlayed;
  bool _isRetired = false;

  final _tags = <String>[];
  int? _recommendation;
  int? _spending;
  int? _returnBarrier;
  final _tagInputController = TextEditingController();

  AndroidPackageModel? _linkedPackage;

  late final GameEntry _stub = GameEntry(gameName: '');

  @override
  void dispose() {
    _nameController.dispose();
    _charNameController.dispose();
    _serverController.dispose();
    _levelController.dispose();
    _playHoursController.dispose();
    _progressController.dispose();
    _notesController.dispose();
    _tagInputController.dispose();
    super.dispose();
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

  Future<void> _pickPackage() async {
    final packages = await PackageInfoService.getInstalledPackages();
    if (!mounted) return;
    final selected = await showDialog<AndroidPackageModel>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择本地应用'),
        children: packages.map((p) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Text('${p.appName}\n${p.packageName}',
                  style: const TextStyle(fontSize: 13)),
            )).toList(),
      ),
    );
    if (selected != null) {
      setState(() => _linkedPackage = selected);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('游戏名称不能为空')),
      );
      return;
    }

    final game = GameEntry(
      gameName: name,
      characterName:
          _charNameController.text.trim().isEmpty ? null : _charNameController.text.trim(),
      server: _serverController.text.trim().isEmpty ? null : _serverController.text.trim(),
      level: int.tryParse(_levelController.text.trim()),
      gamePlayedSeconds: GameAtomModel.playHoursToSeconds(_playHoursController.text.trim()),
      gameLastLaunched: _lastPlayed,
      isRetired: _isRetired,
      progress:
          _progressController.text.trim().isEmpty ? null : _progressController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      tags: List.from(_tags),
      recommendation: _recommendation,
      spending: _spending,
      returnBarrier: _returnBarrier,
      resources: Map.from(_stub.resources),
      linkedPackageName: _linkedPackage?.packageName,
    );

    Navigator.pop(context, game);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加游戏'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: '创建',
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '游戏名称 *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _charNameController,
              decoration: const InputDecoration(
                labelText: '角色名 / 游戏内ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: '区服',
                border: OutlineInputBorder(),
              ),
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
                    decoration: const InputDecoration(
                      labelText: '等级',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _playHoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '游戏时长 (小时)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('资源',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            ResourcesEditor(game: _stub, enabled: true),

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
                  child: Text(
                    _lastPlayed != null ? _formatDate(_lastPlayed!) : '点击选择日期',
                  ),
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
            _sectionLabel('系统集成'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickPackage,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '关联本地应用',
                  suffixIcon: Icon(Icons.android),
                ),
                child: Text(
                  _linkedPackage?.appName ?? '点击选择已安装的应用（可选）',
                  style: TextStyle(
                    color: _linkedPackage != null ? null : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _sectionLabel('其他'),
            const SizedBox(height: 8),
            TextField(
              controller: _progressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '当前进度',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('标签',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}
