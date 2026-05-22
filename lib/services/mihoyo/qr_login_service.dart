import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'mihoyo_api_client.dart';
import 'device_id.dart';

enum QrLoginStatus { created, scanned, confirmed, error }

class QrLoginResult {
  final QrLoginStatus status;
  const QrLoginResult({required this.status});
}

class QrLoginService {
  static const _createUrl =
      'https://passport-api.miyoushe.com/account/ma-cn-passport/web/createQRLogin';
  static const _queryUrl =
      'https://passport-api.miyoushe.com/account/ma-cn-passport/web/queryQRLoginStatus';
  static const _appId = 'bll8iq97cem8';

  static const _ua =
      'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36';

  final Duration _pollInterval;

  QrLoginService({Duration? pollInterval})
      : _pollInterval = pollInterval ?? const Duration(seconds: 2);

  Future<Map<String, String>> createQRLogin() async {
    final deviceId = await DeviceIdService.getOrCreate();
    final client = MihoyoApiClient();
    final data = await client.post(
      Uri.parse(_createUrl),
      cookie: '',
      headers: {
        'x-rpc-app_id': _appId,
        'x-rpc-device_id': deviceId,
      },
    );

    final inner = data['data'] as Map<String, dynamic>;
    final url = (inner['url'] as String).replaceAll(r'\u0026', '&');
    final ticket = inner['ticket'] as String;
    return {'url': url, 'ticket': ticket};
  }

  Stream<QrLoginResult> pollStatus(String ticket) async* {
    final deviceId = await DeviceIdService.getOrCreate();

    while (true) {
      final (data, cookieStr) =
          await _postPollWithCookies(ticket, deviceId);
      final inner = data['data'] as Map<String, dynamic>?;
      final status = inner?['status'] as String? ?? '';

      switch (status) {
        case 'Confirmed':
          if (cookieStr.isNotEmpty) {
            await MihoyoApiClient.saveCookie(cookieStr);
          }
          yield const QrLoginResult(status: QrLoginStatus.confirmed);
          return;
        case 'Scanned':
          yield const QrLoginResult(status: QrLoginStatus.scanned);
          break;
        case 'Created':
          yield const QrLoginResult(status: QrLoginStatus.created);
          break;
        default:
          yield const QrLoginResult(status: QrLoginStatus.error);
          return;
      }

      await Future.delayed(_pollInterval);
    }
  }

  Future<(Map<String, dynamic>, String)> _postPollWithCookies(
      String ticket, String deviceId) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(_queryUrl));
      request.headers
        ..set('Content-Type', 'application/json')
        ..set('x-rpc-app_id', _appId)
        ..set('x-rpc-device_id', deviceId)
        ..set('User-Agent', _ua);
      request.write(json.encode({'ticket': ticket}));

      final response = await request.close();
      final respBody = await response.transform(utf8.decoder).join();

      final cookieParts = <String>[];
      response.headers.forEach((name, values) {
        if (name == 'set-cookie') {
          for (final v in values) {
            cookieParts.add(v.split(';').first.trim());
          }
        }
      });

      return (
        json.decode(respBody) as Map<String, dynamic>,
        cookieParts.join('; '),
      );
    } finally {
      client.close();
    }
  }
}
