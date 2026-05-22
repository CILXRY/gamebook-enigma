import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/request_log_entry.dart';
import '../log_service.dart';

class MihoyoApiClient {
  static const _cookieKey = 'mihoyo_cookie';

  final http.Client _httpClient;

  MihoyoApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static Future<String?> loadCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookieKey);
  }

  static Future<void> saveCookie(String cookie) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookieKey, cookie);
  }

  Future<Map<String, dynamic>> get(
    Uri url, {
    String? cookie,
    Map<String, String>? headers,
  }) async {
    return _request('GET', url, cookie: cookie, headers: headers);
  }

  Future<Map<String, dynamic>> post(
    Uri url, {
    Map<String, dynamic>? body,
    String? cookie,
    Map<String, String>? headers,
  }) async {
    return _request('POST', url,
        body: body, cookie: cookie, headers: headers);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Uri url, {
    Map<String, dynamic>? body,
    String? cookie,
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
      ...?headers,
    };

    final resolvedCookie = cookie ?? await loadCookie();
    if (resolvedCookie != null && resolvedCookie.isNotEmpty) {
      mergedHeaders['Cookie'] = resolvedCookie;
    }

    final startTime = DateTime.now();
    final seq = LogService().nextSeq();
    final encodedBody = body != null ? json.encode(body) : null;

    late final http.Response response;
    if (method == 'POST') {
      response = await _httpClient.post(
        url,
        headers: mergedHeaders,
        body: encodedBody,
      );
    } else {
      response = await _httpClient.get(url, headers: mergedHeaders);
    }

    final entry = RequestLogEntry(
      seq: seq,
      timestamp: startTime,
      method: method,
      url: url.toString(),
      requestHeaders: Map.from(mergedHeaders),
      requestBody: encodedBody,
      statusCode: response.statusCode,
      responseBody: response.body,
      duration: DateTime.now().difference(startTime),
    );

    if (response.statusCode != 200) {
      LogService().add(entry);
      throw MihoyoApiException(response.statusCode, response.body);
    }

    LogService().add(entry);
    return json.decode(response.body) as Map<String, dynamic>;
  }
}

class MihoyoApiException implements Exception {
  final int statusCode;
  final String body;

  const MihoyoApiException(this.statusCode, this.body);

  @override
  String toString() => 'MihoyoApiException($statusCode): $body';
}
