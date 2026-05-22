import 'package:flutter/foundation.dart';

import '../models/request_log_entry.dart';

class LogService {
  static final LogService _instance = LogService._();
  factory LogService() => _instance;
  LogService._();

  static const _maxEntries = 50;

  final _entries = <RequestLogEntry>[];
  final ValueNotifier<int> _notifier = ValueNotifier(0);
  int _seq = 0;

  ValueNotifier<int> get notifier => _notifier;
  List<RequestLogEntry> get entries => List.unmodifiable(_entries);
  int get count => _entries.length;

  int nextSeq() => ++_seq;

  void add(RequestLogEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries.removeLast();
    }
    _notifier.value++;
  }

  void clear() {
    _entries.clear();
    _notifier.value++;
  }
}
