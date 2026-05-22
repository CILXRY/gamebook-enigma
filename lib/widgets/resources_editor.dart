import 'package:flutter/material.dart';

class ResourcesEditor extends StatefulWidget {
  final Map<String, dynamic> initialResources;
  final bool enabled;
  final ValueChanged<Map<String, dynamic>>? onChanged;

  const ResourcesEditor({
    super.key,
    this.initialResources = const {},
    this.enabled = true,
    this.onChanged,
  });

  @override
  State<ResourcesEditor> createState() => _ResourcesEditorState();
}

class _ResourcesEditorState extends State<ResourcesEditor> {
  late List<_ResourceEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.initialResources.entries
        .map((e) => _ResourceEntry(
              keyController: TextEditingController(text: e.key),
              valueController: TextEditingController(text: e.value.toString()),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.keyController.dispose();
      e.valueController.dispose();
    }
    super.dispose();
  }

  void _sync() {
    final map = <String, dynamic>{
      for (final e in _entries)
        if (e.keyController.text.trim().isNotEmpty)
          e.keyController.text.trim(): int.tryParse(e.valueController.text) ??
              double.tryParse(e.valueController.text) ??
              e.valueController.text,
    };
    widget.onChanged?.call(map);
  }

  void _addRow() {
    setState(() {
      _entries.add(_ResourceEntry(
        keyController: TextEditingController(),
        valueController: TextEditingController(),
      ));
    });
  }

  void _removeRow(int index) {
    setState(() {
      _entries[index].keyController.dispose();
      _entries[index].valueController.dispose();
      _entries.removeAt(index);
    });
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(_entries.length, (i) {
          final e = _entries[i];
          if (widget.enabled) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: e.keyController,
                      decoration: const InputDecoration(
                        hintText: '资源名',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => _sync(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: e.valueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '数值',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => _sync(),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle, size: 20),
                      color: Colors.red[300],
                      onPressed: () => _removeRow(i),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text('${e.keyController.text}: ',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(e.valueController.text),
                ],
              ),
            );
          }
        }),
        if (_entries.isEmpty)
          Text(widget.enabled ? '暂无资源，点击下方添加' : '暂无资源',
              style: const TextStyle(color: Colors.grey)),
        if (widget.enabled)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加资源'),
            ),
          ),
      ],
    );
  }
}

class _ResourceEntry {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _ResourceEntry({required this.keyController, required this.valueController});
}
