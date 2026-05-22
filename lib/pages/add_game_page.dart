import 'package:flutter/material.dart';
import '../models/account_info.dart';
import '../models/android_package_model.dart';
import '../models/game_atom_model.dart';
import '../models/game_entry.dart';
import '../models/sentence_template.dart';
import '../models/tag_fill.dart';
import '../services/package_info_service.dart';
import '../services/storage_service.dart';
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

  final _tagFills = <TagFill>[];
  List<SentenceTemplate> _templates = [];
  List<String> _presetTags = [];
  int? _recommendation;
  int? _spending;
  int? _returnBarrier;
  bool _hasAccount = false;
  final _tagInputController = TextEditingController();

  AndroidPackageModel? _linkedPackage;
  Map<String, dynamic> _resources = {};

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await StorageService.loadSentenceTemplates();
    final presetTags = await StorageService.loadPresetTags();
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _presetTags = presetTags;
    });
  }

  TagFill? _findFill(String sentenceKey) {
    try {
      return _tagFills.firstWhere((tf) => tf.sentenceKey == sentenceKey);
    } catch (_) {
      return null;
    }
  }

  void _toggleTemplate(SentenceTemplate tmpl, bool enabled) {
    setState(() {
      if (enabled) {
        _tagFills.add(TagFill(sentenceKey: tmpl.key, tag: _presetTags.isNotEmpty ? _presetTags.first : ''));
      } else {
        _tagFills.removeWhere((tf) => tf.sentenceKey == tmpl.key);
      }
    });
  }

  void _setTag(String sentenceKey, String tag) {
    setState(() {
      final existing = _findFill(sentenceKey);
      if (existing != null) {
        existing.tag = tag;
      }
    });
  }

  void _addCustomTag() {
    final t = _tagInputController.text.trim();
    if (t.isEmpty || _presetTags.contains(t)) return;
    setState(() {
      _presetTags.add(t);
      _tagInputController.clear();
    });
    StorageService.savePresetTags(_presetTags);
  }

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

    AccountInfo? accountInfo;
    if (_hasAccount) {
      final charName = _charNameController.text.trim().isEmpty ? null : _charNameController.text.trim();
      final server = _serverController.text.trim().isEmpty ? null : _serverController.text.trim();
      final level = int.tryParse(_levelController.text.trim());
      if (charName != null || server != null || level != null || _spending != null || _resources.isNotEmpty) {
        accountInfo = AccountInfo(
          characterName: charName,
          server: server,
          level: level,
          spending: _spending,
          resources: Map.from(_resources),
        );
      }
    }

    final game = GameEntry(
      gameName: name,
      accountInfo: accountInfo,
      gamePlayedSeconds: GameAtomModel.playHoursToSeconds(_playHoursController.text.trim()),
      gameLastLaunched: _lastPlayed,
      isRetired: _isRetired,
      progress:
          _progressController.text.trim().isEmpty ? null : _progressController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      tagFills: List.from(_tagFills),
      recommendation: _recommendation,
      returnBarrier: _returnBarrier,
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

            const SizedBox(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('有账号体系'),
              subtitle: Text(_hasAccount ? '显示角色名/等级/资源等' : '纯单机游戏'),
              value: _hasAccount,
              onChanged: (v) => setState(() {
                _hasAccount = v;
                if (!v) {
                  _spending = null;
                  _charNameController.clear();
                  _serverController.clear();
                  _levelController.clear();
                  _resources = {};
                }
              }),
            ),
            if (_hasAccount) ...[
              const SizedBox(height: 8),
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
              ResourcesEditor(
                initialResources: _resources,
                enabled: true,
                onChanged: (v) {
                  setState(() => _resources = v);
                },
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextField(
                controller: _playHoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '游戏时长 (小时)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 24),
            _sectionLabel('主观评价'),
            const SizedBox(height: 8),
            _buildFillEditor(),
            const SizedBox(height: 20),
            _buildChoiceField('推荐度', {
              3: '👍 推荐',
              2: '🙂 还行',
              1: '👎 不推荐',
            }, _recommendation, (v) => setState(() => _recommendation = v)),
            const SizedBox(height: 16),
            if (_hasAccount) ...[
              _buildChoiceField('氪金程度', {
                0: '🆓 零氪',
                1: '☕ 微氪',
                2: '💰 中氪',
                3: '🐳 重氪',
              }, _spending, (v) => setState(() => _spending = v)),
              const SizedBox(height: 16),
            ],
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

  Widget _buildFillEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('选词填空',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        ..._templates.map((tmpl) => _buildTemplateRow(tmpl)),
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
              tooltip: '添加自定义标签到预设库',
              onPressed: _addCustomTag,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplateRow(SentenceTemplate tmpl) {
    final fill = _findFill(tmpl.key);
    final isEnabled = fill != null;
    final selectedTag = fill?.tag ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Checkbox(
            value: isEnabled,
            onChanged: (v) => _toggleTemplate(tmpl, v ?? false),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: isEnabled ? _buildFilledSentence(tmpl, selectedTag) : Text(
              tmpl.format,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilledSentence(SentenceTemplate tmpl, String selectedTag) {
    final parts = tmpl.format.split('{tag}');
    return Row(
      children: [
        if (parts.isNotEmpty)
          Text(parts[0], style: const TextStyle(fontSize: 14)),
        _tagSelector(tmpl.key, selectedTag),
        if (parts.length > 1)
          Flexible(
            child: Text(parts[1], style: const TextStyle(fontSize: 14)),
          ),
      ],
    );
  }

  Widget _tagSelector(String sentenceKey, String currentTag) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (tag) => _setTag(sentenceKey, tag),
      child: Chip(
        label: Text(currentTag.isEmpty ? '选择标签' : currentTag,
            style: const TextStyle(fontSize: 12)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      itemBuilder: (context) => _presetTags.map((t) => PopupMenuItem<String>(
            value: t,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(t, style: const TextStyle(fontSize: 14)),
          )).toList(),
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
