import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/request_log_entry.dart';
import '../services/log_service.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  List<RequestLogEntry> _entries = [];
  final Map<int, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    _entries = List.from(LogService().entries);
    LogService().notifier.addListener(_onLogUpdate);
  }

  @override
  void dispose() {
    LogService().notifier.removeListener(_onLogUpdate);
    super.dispose();
  }

  void _onLogUpdate() {
    if (!mounted) return;
    setState(() {
      _entries = List.from(LogService().entries);
    });
  }

  void _toggleExpand(int seq) {
    setState(() {
      _expanded[seq] = !(_expanded[seq] ?? false);
    });
  }

  void _clearAll() {
    LogService().clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('请求日志'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '清除',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _entries.isEmpty
          ? const Center(
              child: Text('暂无请求记录', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final isExpanded = _expanded[entry.seq] ?? false;
                return _LogTile(
                  entry: entry,
                  isExpanded: isExpanded,
                  onTap: () => _toggleExpand(entry.seq),
                );
              },
            ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final RequestLogEntry entry;
  final bool isExpanded;
  final VoidCallback onTap;

  const _LogTile({
    required this.entry,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOk = entry.isSuccess;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: entry.statusCode != null
                          ? (isOk ? Colors.green[100] : Colors.red[100])
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.statusCode?.toString() ?? '--',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: entry.statusCode != null
                            ? (isOk ? Colors.green[800] : Colors.red[800])
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.method,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: entry.method == 'POST'
                          ? Colors.deepPurple[600]
                          : Colors.blue[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.summaryUrl,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.duration != null)
                    Text(
                      '${entry.duration!.inMilliseconds}ms',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatTime(entry.timestamp)}  #${entry.seq}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              if (entry.errorMessage != null)
                Text(
                  entry.errorMessage!,
                  style: TextStyle(fontSize: 11, color: Colors.red[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (isExpanded) ...[
                const Divider(height: 16),
                _buildDetailSection(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle('Request Headers'),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _formatHeaders(entry.requestHeaders),
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
        if (entry.requestBody != null &&
            entry.requestBody!.isNotEmpty) ...[
          _buildSubtitle('Request Body'),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              entry.requestBody!,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ],
        _buildSubtitle(
            'Response${entry.responseBody != null ? " (${entry.responseBody!.length} chars)" : ""}'),
        if (entry.responseBody != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: entry.isSuccess ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              entry.responseBody!,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              maxLines: 30,
              overflow: TextOverflow.fade,
            ),
          ),
        _buildSubtitle('curl 命令'),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    entry.curlCommand,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '复制',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: entry.curlCommand));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('curl 已复制到剪贴板')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600]),
      ),
    );
  }

  String _formatHeaders(Map<String, String> headers) {
    return headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
