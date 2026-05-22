import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/sentence_template.dart';
import '../services/storage_service.dart';
import '../services/mihoyo/mihoyo_api_client.dart';
import '../services/mihoyo/endpoint_service.dart';
import '../services/mihoyo/device_id.dart';
import '../services/mihoyo/device_fp_service.dart';
import '../services/mihoyo/device_info_provider.dart';
import '../services/mihoyo/ds_service.dart';
import '../services/mihoyo/qr_login_service.dart';
import '../services/package_info_service.dart';
import '../constants/preset_defaults.dart';
import 'log_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _cookie;
  Map<String, String> _endpoints = {};
  String _deviceId = '';
  String _deviceFp = '';
  String _seedId = '';
  bool _isLoadingFp = false;
  String _ds1 = '';
  final _ds2BodyController = TextEditingController();
  final _ds2QueryController = TextEditingController();
  String _ds2Result = '';

  bool _usagePermissionGranted = false;
  List<SentenceTemplate> _templates = [];
  List<String> _presetTags = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cookie = await MihoyoApiClient.loadCookie();
    final endpoints = await EndpointService.loadAll();
    final deviceId = await DeviceIdService.getOrCreate();
    final deviceFp = await DeviceFpService.loadDeviceFp();
    final seedId = await DeviceFpService.loadSeedId();
    final usagePerm = await PackageInfoService.isUsagePermissionGranted();
    final templates = await StorageService.loadSentenceTemplates();
    final presetTags = await StorageService.loadPresetTags();
    if (!mounted) return;
    setState(() {
      _cookie = cookie;
      _endpoints = endpoints;
      _deviceId = deviceId;
      _deviceFp = deviceFp ?? '';
      _seedId = seedId ?? '';
      _ds1 = DsService.generateDS1().ds;
      _usagePermissionGranted = usagePerm;
      _templates = templates;
      _presetTags = presetTags;
    });
  }

  @override
  void dispose() {
    _ds2BodyController.dispose();
    _ds2QueryController.dispose();
    super.dispose();
  }

  Future<void> _showCookieDialog() async {
    final controller = TextEditingController(text: _cookie ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('米游社 Cookie'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('如何获取：',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text(
                '1. 浏览器打开 bbs.mihoyo.com 并登录\n'
                '2. 按 F12 → Application → Cookies\n'
                '3. 复制 Cookie 完整字符串',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Cookie',
                  border: OutlineInputBorder(),
                  hintText: '在此粘贴 Cookie...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              await MihoyoApiClient.saveCookie(controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved == true) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cookie 已保存')),
        );
      }
    }
  }

  Future<void> _clearCookie() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除 Cookie'),
        content: const Text('确定要清除已保存的 Cookie 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await MihoyoApiClient.saveCookie('');
      _loadData();
    }
  }

  Future<void> _showQRLogin() async {
    final closed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _QRLoginDialog(),
    );
    if (closed == true) {
      _loadData();
    }
  }

  Future<void> _regenerateDeviceId() async {
    await DeviceIdService.regenerate();
    _loadData();
  }

  Future<void> _editEndpoint(String gameBiz, String gameName) async {
    final controller = TextEditingController(text: _endpoints[gameBiz] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('$gameName API 端点'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('使用 {UID} 作为角色 ID 占位符',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '输入 API URL...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await EndpointService.resetDefault(gameBiz);
                final defaults = await EndpointService.loadAll();
                controller.text = defaults[gameBiz] ?? '';
                setDialogState(() {});
              },
              child: const Text('恢复默认'),
            ),
            FilledButton(
              onPressed: () async {
                await EndpointService.save(gameBiz, controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    _loadData();
  }

  Future<void> _refreshDeviceFp() async {
    setState(() => _isLoadingFp = true);
    try {
      final service = DeviceFpService();
      await service.regenerate();
      if (!mounted) return;
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device FP 已刷新')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingFp = false);
    }
  }

  Future<void> _clearDeviceFp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除 Device FP'),
        content: const Text('确定要清除 Device Fingerprint 吗？下次需要时会自动重新获取。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DeviceFpService.clear();
      _loadData();
    }
  }

  Future<void> _showExtFieldsEditor() async {
    final existing = await DeviceInfoProvider.loadOverride();
    String rawText = existing ?? '';
    if (rawText.isEmpty) {
      final collected = await DeviceInfoProvider.collect();
      final sorted = Map.fromEntries(
        collected.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      rawText = const JsonEncoder.withIndent('  ').convert(sorted);
    }

    final controller = TextEditingController(text: rawText);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设备信息 (ext_fields)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: TextField(
              controller: controller,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'JSON 格式的设备信息',
              ),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await DeviceInfoProvider.clearOverride();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('恢复默认'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              try {
                json.decode(text);
              } catch (_) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('JSON 格式无效')),
                );
                return;
              }
              await DeviceInfoProvider.saveOverride(text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _refreshDs1() {
    setState(() {
      _ds1 = DsService.generateDS1().ds;
    });
  }

  void _onDs2Changed() {
    final b = _ds2BodyController.text.trim();
    final q = _ds2QueryController.text.trim();
    setState(() {
      _ds2Result = DsService.generateDS2(body: b, query: q).ds;
    });
  }

  // ── build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('权限'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.shield,
                      color: _usagePermissionGranted
                          ? Colors.green
                          : Colors.orange),
                  title: const Text('使用情况访问权限'),
                  subtitle: Text(
                    _usagePermissionGranted
                        ? '已授权 — 可读取应用使用时长'
                        : '未授权 — 点击跳转设置',
                    style: TextStyle(
                      color: _usagePermissionGranted
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _usagePermissionGranted
                      ? null
                      : () async {
                          await PackageInfoService.openUsageSettings();
                        },
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('查询所有应用'),
                  subtitle: Text('已声明 — 用于扫描已安装游戏',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('选词填空设置'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _buildTemplatesTile(),
                const Divider(height: 1),
                _buildPresetTagsTile(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('米游社账户'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cookie),
                  title: const Text('Cookie'),
                  subtitle: Text(_cookie != null && _cookie!.isNotEmpty
                      ? '已设置 (${_cookie!.length} 字符)'
                      : '未设置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showCookieDialog,
                ),
                if (_cookie != null && _cookie!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    title: const Text('清除 Cookie',
                        style: TextStyle(color: Colors.red)),
                    onTap: _clearCookie,
                  ),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text('扫码登录'),
                  onTap: _showQRLogin,
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('X-RPC-Device-Id'),
                  subtitle: Text(_deviceId, style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: '重新生成',
                    onPressed: _regenerateDeviceId,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.devices_other),
                  title: const Text('Device Fingerprint'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _deviceFp.isNotEmpty ? _deviceFp : '未获取',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'seed: $_seedId',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoadingFp)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: '重新获取',
                          onPressed: _refreshDeviceFp,
                        ),
                      if (_deviceFp.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          tooltip: '清除',
                          onPressed: _clearDeviceFp,
                        ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('设备信息配置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showExtFieldsEditor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('DS 签名预览'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    dense: true,
                    title: const Text('DS1 (米游社)',
                        style: TextStyle(fontSize: 14)),
                    subtitle: Text(_ds1,
                        style: const TextStyle(
                            fontSize: 11, fontFamily: 'monospace')),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: '刷新',
                      onPressed: _refreshDs1,
                    ),
                  ),
                  const Divider(height: 1),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        dense: true,
                        title: const Text('DS2 (游戏数据)',
                            style: TextStyle(fontSize: 14)),
                        subtitle: Text(
                            _ds2Result.isNotEmpty
                                ? _ds2Result
                                : '输入 body / query 预览',
                            style: const TextStyle(
                                fontSize: 11, fontFamily: 'monospace')),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: '刷新',
                          onPressed: _onDs2Changed,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _ds2BodyController,
                          decoration: const InputDecoration(
                            labelText: 'body',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace'),
                          onChanged: (_) => _onDs2Changed(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                        child: TextField(
                          controller: _ds2QueryController,
                          decoration: const InputDecoration(
                            labelText: 'query',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace'),
                          onChanged: (_) => _onDs2Changed(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('API 端点'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _endpointTile('hkrpg_cn', '崩坏：星穹铁道'),
                const Divider(height: 1),
                _endpointTile('hk4e_cn', '原神'),
                const Divider(height: 1),
                _endpointTile('nap_cn', '绝区零'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('调试'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('请求日志'),
              subtitle: const Text('查看 API 请求记录与 curl 命令'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesTile() {
    return ListTile(
      leading: const Icon(Icons.format_quote),
      title: const Text('管理句子模板'),
      subtitle: Text('${_templates.length} 个模板 (可编辑、增减)',
          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showTemplatesPage(),
    );
  }

  Widget _buildPresetTagsTile() {
    return ListTile(
      leading: const Icon(Icons.label),
      title: const Text('管理预设标签'),
      subtitle: Text('${_presetTags.length} 个标签 (填空选项)',
          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showPresetTagsPage(),
    );
  }

  void _showTemplatesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _TemplatesManagementPage(
        templates: _templates,
        onTemplatesChanged: (updated) async {
          await StorageService.saveSentenceTemplates(updated);
          setState(() => _templates = updated);
        },
        onReset: () async {
          await StorageService.resetSentenceTemplates();
          setState(() {
            _templates = List.from(defaultSentenceTemplates);
          });
        },
      )),
    );
  }

  void _showPresetTagsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PresetTagsManagementPage(
        tags: _presetTags,
        onTagsChanged: (updated) async {
          await StorageService.savePresetTags(updated);
          setState(() => _presetTags = updated);
        },
        onReset: () async {
          await StorageService.resetPresetTags();
          setState(() {
            _presetTags = List.from(defaultPresetTags);
          });
        },
      )),
    );
  }

  Widget _endpointTile(String gameBiz, String gameName) {
    final url = _endpoints[gameBiz];
    final hasUrl = url != null && url.isNotEmpty;
    return ListTile(
      title: Text(gameName),
      subtitle: Text(
        hasUrl ? url : '(待抓包)',
        style: TextStyle(
          fontSize: 12,
          color: hasUrl ? Colors.grey[600] : Colors.orange,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _editEndpoint(gameBiz, gameName),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _TemplateEditResult {
  final String key;
  final String format;
  const _TemplateEditResult({required this.key, required this.format});
}

// ── templates management sub-page ───────────────────────────────────

class _TemplatesManagementPage extends StatefulWidget {
  final List<SentenceTemplate> templates;
  final ValueChanged<List<SentenceTemplate>> onTemplatesChanged;
  final VoidCallback onReset;

  const _TemplatesManagementPage({
    required this.templates,
    required this.onTemplatesChanged,
    required this.onReset,
  });

  @override
  State<_TemplatesManagementPage> createState() => _TemplatesManagementPageState();
}

class _TemplatesManagementPageState extends State<_TemplatesManagementPage> {
  late List<SentenceTemplate> _templates;

  @override
  void initState() {
    super.initState();
    _templates = List.from(widget.templates);
  }

  Future<void> _add() async {
    final keyController = TextEditingController();
    final formatController = TextEditingController();

    final result = await showDialog<_TemplateEditResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加句子模板'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Key (唯一标识)',
                border: OutlineInputBorder(),
                hintText: 'e.g. suitable_for',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: formatController,
              decoration: const InputDecoration(
                labelText: '格式',
                border: OutlineInputBorder(),
                hintText: '使用 {tag} 作为填空占位符',
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
              final k = keyController.text.trim();
              final f = formatController.text.trim();
              if (k.isEmpty || f.isEmpty || !f.contains('{tag}')) return;
              Navigator.pop(ctx, _TemplateEditResult(key: k, format: f));
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (_templates.any((t) => t.key == result.key)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Key 已存在')),
          );
        }
        return;
      }
      _templates.add(SentenceTemplate(key: result.key, format: result.format));
      widget.onTemplatesChanged(_templates);
      setState(() {});
    }
  }

  Future<void> _edit(SentenceTemplate tmpl) async {
    final keyController = TextEditingController(text: tmpl.key);
    final formatController = TextEditingController(text: tmpl.format);

    final result = await showDialog<_TemplateEditResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑句子模板'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: formatController,
              decoration: const InputDecoration(
                labelText: '格式',
                border: OutlineInputBorder(),
                hintText: '使用 {tag} 作为填空占位符',
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
              final k = keyController.text.trim();
              final f = formatController.text.trim();
              if (k.isEmpty || f.isEmpty || !f.contains('{tag}')) return;
              Navigator.pop(ctx, _TemplateEditResult(key: k, format: f));
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null) {
      tmpl.key = result.key;
      tmpl.format = result.format;
      widget.onTemplatesChanged(_templates);
      setState(() {});
    }
  }

  Future<void> _delete(SentenceTemplate tmpl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定删除「${tmpl.format}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _templates.removeWhere((t) => t.key == tmpl.key);
      widget.onTemplatesChanged(_templates);
      setState(() {});
    }
  }

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复默认模板'),
        content: const Text('确定将句子模板恢复为默认值吗？自定义的模板将丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onReset();
      setState(() {
        _templates = List.from(defaultSentenceTemplates);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理句子模板'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '恢复默认',
            onPressed: _resetAll,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加模板',
            onPressed: _add,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('填空格式中使用 {tag} 作为占位符',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 12),
          if (_templates.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('暂无模板，点击右上角 + 添加',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ..._templates.map((tmpl) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(tmpl.format, style: const TextStyle(fontSize: 14)),
                    subtitle: Text('key: ${tmpl.key}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _edit(tmpl),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          onPressed: () => _delete(tmpl),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

// ── preset tags management sub-page ─────────────────────────────────

class _PresetTagsManagementPage extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final VoidCallback onReset;

  const _PresetTagsManagementPage({
    required this.tags,
    required this.onTagsChanged,
    required this.onReset,
  });

  @override
  State<_PresetTagsManagementPage> createState() => _PresetTagsManagementPageState();
}

class _PresetTagsManagementPageState extends State<_PresetTagsManagementPage> {
  late List<String> _tags;
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.tags);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final t = _inputController.text.trim();
    if (t.isEmpty || _tags.contains(t)) return;
    _tags.add(t);
    widget.onTagsChanged(_tags);
    setState(() {
      _inputController.clear();
    });
  }

  Future<void> _edit(String oldTag) async {
    final controller = TextEditingController(text: oldTag);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑标签'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '标签名',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final newTag = controller.text.trim();
      if (newTag != oldTag) {
        final idx = _tags.indexOf(oldTag);
        if (idx >= 0) {
          _tags[idx] = newTag;
        }
        widget.onTagsChanged(_tags);
        setState(() {});
      }
    }
  }

  Future<void> _delete(String tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除标签'),
        content: Text('确定删除「$tag」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _tags.remove(tag);
      widget.onTagsChanged(_tags);
      setState(() {});
    }
  }

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复默认标签'),
        content: const Text('确定将预设标签恢复为默认值吗？自定义标签将丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onReset();
      setState(() {
        _tags = List.from(defaultPresetTags);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理预设标签'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '恢复默认',
            onPressed: _resetAll,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    hintText: '输入新标签...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.add),
                onPressed: _add,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((t) => InputChip(
                  label: Text(t, style: const TextStyle(fontSize: 13)),
                  onDeleted: () => _delete(t),
                  onPressed: () => _edit(t),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
          ),
          if (_tags.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child:
                      Text('暂无标签', style: TextStyle(color: Colors.grey))),
            ),
        ],
      ),
    );
  }
}

// ── QR Login Dialog ─────────────────────────────────────────────────

class _QRLoginDialog extends StatefulWidget {
  const _QRLoginDialog();

  @override
  State<_QRLoginDialog> createState() => _QRLoginDialogState();
}

class _QRLoginDialogState extends State<_QRLoginDialog> {
  late final QrLoginService _service;

  String? _qrUrl;
  final ValueNotifier<String> _statusNotifier =
      ValueNotifier('正在生成二维码...');
  bool _canClose = false;
  StreamSubscription<QrLoginResult>? _subscription;

  @override
  void initState() {
    super.initState();
    _service = QrLoginService();
    _start();
  }

  Future<void> _start() async {
    try {
      final result = await _service.createQRLogin();
      if (!mounted) return;
      _qrUrl = result['url'];
      _statusNotifier.value = '等待扫码...';
      _canClose = true;
      setState(() {});
      _startPolling(result['ticket']!);
    } catch (e) {
      if (!mounted) return;
      _statusNotifier.value = '创建失败: $e';
      setState(() => _canClose = true);
    }
  }

  void _startPolling(String ticket) {
    _subscription = _service.pollStatus(ticket).listen(
      (result) {
        if (!mounted) return;
        switch (result.status) {
          case QrLoginStatus.created:
            _statusNotifier.value = '等待扫码...';
          case QrLoginStatus.scanned:
            _statusNotifier.value = '已扫描，请在 App 中确认登录';
          case QrLoginStatus.confirmed:
            _statusNotifier.value = '登录成功！';
            setState(() => _canClose = true);
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) Navigator.pop(context, true);
            });
          case QrLoginStatus.error:
            _statusNotifier.value = '登录失败，请重试';
            setState(() => _canClose = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _statusNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('米游社扫码登录'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_qrUrl != null)
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: _qrUrl!,
                size: 200,
                backgroundColor: Colors.white,
              ),
            )
          else
            SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          const SizedBox(height: 16),
          ValueListenableBuilder<String>(
            valueListenable: _statusNotifier,
            builder: (_, status, _) =>
                Text(status, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _canClose ? () => Navigator.pop(context, false) : null,
          child: const Text('关闭'),
        ),
      ],
    );
  }
}