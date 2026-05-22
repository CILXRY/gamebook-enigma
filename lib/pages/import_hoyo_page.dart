import 'package:flutter/material.dart';

import '../models/account_info.dart';
import '../models/game_entry.dart';
import '../models/mihoyo/collection_stats.dart';
import '../models/mihoyo/hoyo_game_profile.dart';
import '../models/mihoyo/user_game_role.dart';
import '../services/mihoyo/game_data_service.dart';
import '../services/mihoyo/mihoyo_api_client.dart';
import 'settings_page.dart';

class ImportHoyoPage extends StatefulWidget {
  const ImportHoyoPage({super.key});

  @override
  State<ImportHoyoPage> createState() => _ImportHoyoPageState();
}

class _ImportHoyoPageState extends State<ImportHoyoPage> {
  List<UserGameRole>? _roles;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    setState(() {
      _roles = null;
      _error = null;
    });

    final cookie = await MihoyoApiClient.loadCookie();
    if (cookie == null || cookie.isEmpty) {
      if (!mounted) return;
      setState(() => _error = '未设置 Cookie');
      return;
    }

    try {
      final roles =
          await GameDataService().fetchUserGameRoles(cookie: cookie);
      if (!mounted) return;
      if (roles.isEmpty) {
        setState(() => _error = '未找到绑定的游戏角色');
      } else {
        setState(() => _roles = roles);
      }
    } on MihoyoApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = '请求失败 (${e.statusCode}): ${e.body}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '请求失败: $e');
    }
  }

  void _createFromRole(UserGameRole role) {
    final game = GameEntry(
      gameName: role.gameName,
      accountInfo: AccountInfo(
        characterName: role.nickname.isNotEmpty ? role.nickname : null,
        server: role.regionName.isNotEmpty ? role.regionName : null,
        level: role.level,
      ),
      hoyoProfile: HoyoGameProfile(
        gameBiz: role.gameBiz,
        gameName: role.gameName,
        gameUid: role.gameUid,
        gameNickname: role.nickname,
        gameLevel: role.level ?? 0,
        gameServer: role.regionName,
        collections:
            CollectionStats(activeDays: 0, avatarsCollected: 0, achievementsCollected: 0, chestCollected: 0),
      ),
    );
    Navigator.pop(context, game);
  }

  void _goSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('从米游社导入'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (_error == '未设置 Cookie')
                FilledButton.icon(
                  onPressed: _goSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('前往设置登录'),
                )
              else ...[
                FilledButton.icon(
                  onPressed: _fetchRoles,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_roles == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _roles!.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final role = _roles![index];
        return ListTile(
          leading: _gameIcon(role.gameBiz),
          title: Text(role.nickname.isNotEmpty ? role.nickname : role.gameName),
          subtitle: Text(
            [
              role.gameName,
              'UID: ${role.gameUid}',
              if (role.level != null) 'Lv.${role.level}',
              role.regionName,
            ].join('  ·  '),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _createFromRole(role),
        );
      },
    );
  }

  Widget _gameIcon(String gameBiz) {
    IconData icon = Icons.sports_esports;
    switch (gameBiz) {
      case 'hkrpg_cn':
        icon = Icons.rocket_launch;
      case 'hk4e_cn':
        icon = Icons.auto_awesome;
      case 'nap_cn':
        icon = Icons.flash_on;
    }
    return Icon(icon, color: Theme.of(context).colorScheme.primary);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
