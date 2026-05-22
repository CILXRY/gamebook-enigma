import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class DsHeaders {
  final String ds;
  final Map<String, String> extra;

  const DsHeaders(this.ds, this.extra);
}

class DsService {
  static const saltK2 = 'rtvTthKxEyreVXQCnhluFgLXPOFKPHlA';
  static const saltLk2 = 'EJncUPGnOHajenjLhBOsdpwEMZmiCmQX';
  static const salt4x = 'xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs';
  static const salt6x = 't0qEgfub6cvueAPgR5m9aQWWVciEer7v';

  static const appVersion = '2.71.1';
  static const clientTypeDs1 = '2';
  static const clientTypeDs2 = '5';

  static DsHeaders generateDS1() {
    final t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final r = _randomString(6);
    final main = 'salt=$saltK2&t=$t&r=$r';
    final ds = md5.convert(utf8.encode(main)).toString();

    final extra = <String, String>{
      'x-rpc-client_type': clientTypeDs1,
      'x-rpc-app_version': appVersion,
    };

    return DsHeaders('$t,$r,$ds', extra);
  }

  static DsHeaders generateDS2({String body = '', String query = ''}) {
    final t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int r = 100000 + Random().nextInt(100001);
    if (r == 100000) r = 642367;

    final main = 'salt=$salt4x&t=$t&r=$r&b=$body&q=$query';
    final ds = md5.convert(utf8.encode(main)).toString();

    final extra = <String, String>{
      'x-rpc-client_type': clientTypeDs2,
    };

    return DsHeaders('$t,$r,$ds', extra);
  }

  static String _randomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
