class RequestLogEntry {
  final int seq;
  final DateTime timestamp;
  final String method;
  final String url;
  final Map<String, String> requestHeaders;
  final String? requestBody;
  final int? statusCode;
  final String? responseBody;
  final String? errorMessage;
  final Duration? duration;

  const RequestLogEntry({
    required this.seq,
    required this.timestamp,
    required this.method,
    required this.url,
    this.requestHeaders = const {},
    this.requestBody,
    this.statusCode,
    this.responseBody,
    this.errorMessage,
    this.duration,
  });

  bool get isSuccess => statusCode != null && statusCode == 200;

  String get summaryUrl {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.path + (uri.query.isNotEmpty ? '?...' : '');
  }

  String get curlCommand {
    final buf = StringBuffer('curl -s -X $method');
    for (final entry in requestHeaders.entries) {
      final escapedValue = _escapeShell(entry.value);
      buf.write(" \\\n  -H '${entry.key}: $escapedValue'");
    }
    if (requestBody != null && requestBody!.isNotEmpty) {
      final escapedBody = _escapeShell(requestBody!);
      buf.write(" \\\n  --data-raw '$escapedBody'");
    }
    buf.write(" \\\n  '$_escapeShell(url)'");
    return buf.toString();
  }

  static String _escapeShell(String s) {
    return s.replaceAll("'", "'\\''");
  }
}
