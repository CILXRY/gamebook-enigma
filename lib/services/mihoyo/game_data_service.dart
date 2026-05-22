import '../../models/mihoyo/hoyo_game_profile.dart';
import '../../models/mihoyo/user_game_role.dart';
import 'ds_service.dart';
import 'mihoyo_api_client.dart';
import 'endpoint_service.dart';

class GameDataService {
  final MihoyoApiClient _client;

  GameDataService({MihoyoApiClient? client})
      : _client = client ?? MihoyoApiClient();

  Future<HoyoGameProfile> fetchGameProfile({
    required String gameBiz,
    required String uid,
    String? cookie,
  }) async {
    final template = await EndpointService.load(gameBiz);
    if (template == null || template.isEmpty) {
      throw Exception('游戏 $gameBiz 的 API 端点未配置，请在设置中填写');
    }

    final url = Uri.parse(template.replaceAll('{UID}', uid));
    final sortedQuery = url.query.isNotEmpty
        ? (url.query.split('&')..sort()).join('&')
        : '';
    final dsHeaders = DsService.generateDS2(query: sortedQuery);
    final responseData = await _client.get(
      url,
      cookie: cookie,
      headers: {
        'DS': dsHeaders.ds,
        ...dsHeaders.extra,
      },
    );
    final data = _extractData(responseData);
    final dataWithBiz = <String, dynamic>{
      'game_biz': gameBiz,
      ...data,
    };
    return HoyoGameProfile.fromJson(dataWithBiz);
  }

  Future<List<UserGameRole>> fetchUserGameRoles({String? cookie}) async {
    final url = Uri.parse(
        'https://api-takumi.mihoyo.com/binding/api/getUserGameRolesByCookie');
    final dsHeaders = DsService.generateDS2();
    final responseData = await _client.get(
      url,
      cookie: cookie,
      headers: {
        'DS': dsHeaders.ds,
        ...dsHeaders.extra,
      },
    );
    final data = _extractData(responseData);
    final list = data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => UserGameRole.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    final retCode = response['retcode'] as int? ?? -1;
    if (retCode != 0) {
      final message = response['message'] as String? ?? '未知错误';
      throw MihoyoApiException(retCode, message);
    }
    return response['data'] as Map<String, dynamic>? ?? response;
  }
}
