import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/preset.dart';
import '../../state/rename_session.dart';

Future<void> showPresetsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _PresetsDialog(),
  );
}

class _PresetsDialog extends StatefulWidget {
  const _PresetsDialog();

  @override
  State<_PresetsDialog> createState() => _PresetsDialogState();
}

class _PresetsDialogState extends State<_PresetsDialog> {
  final _nameController = TextEditingController();
  String? _busyMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busyMessage = 'Working…');
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busyMessage = null);
    }
  }

  Future<void> _save() async {
    final session = context.read<RenameSession>();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a preset name.')),
      );
      return;
    }
    await _run(() async {
      await session.savePreset(name);
      _nameController.clear();
    });
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;
    await _run(() => context.read<RenameSession>().importPreset(path));
  }

  Future<void> _export(RulePreset preset) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export preset',
      fileName: '${preset.name}.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (path == null || !mounted) return;
    final out = path.endsWith('.json') ? path : '$path.json';
    await _run(() => context.read<RenameSession>().exportPreset(preset, out));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<RenameSession>();
    final presets = session.presets;

    return AlertDialog(
      title: const Text('Presets'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Save current rules as',
                      hintText: 'Preset name',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busyMessage == null ? _save : null,
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _busyMessage == null ? _import : null,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Import'),
                ),
                const Spacer(),
                if (_busyMessage != null)
                  Text(
                    _busyMessage!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const Divider(height: 24),
            Text(
              presets.isEmpty ? 'No saved presets yet.' : 'Saved presets',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (presets.isEmpty)
              const SizedBox(height: 48)
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: presets.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final preset = presets[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(preset.name),
                      subtitle: Text(
                        '${preset.rules.length} rule${preset.rules.length == 1 ? '' : 's'}',
                      ),
                      trailing: Wrap(
                        spacing: 0,
                        children: [
                          IconButton(
                            tooltip: 'Load',
                            icon: const Icon(Icons.play_arrow, size: 20),
                            onPressed: _busyMessage == null
                                ? () {
                                    session.loadPreset(preset);
                                    Navigator.of(context).pop();
                                  }
                                : null,
                          ),
                          IconButton(
                            tooltip: 'Export',
                            icon: const Icon(Icons.download, size: 20),
                            onPressed: _busyMessage == null
                                ? () => _export(preset)
                                : null,
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: _busyMessage == null
                                ? () => _run(
                                      () => session.deletePreset(preset.id),
                                    )
                                : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
