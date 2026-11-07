import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/rename_session.dart';
import 'widgets/file_list_panel.dart';
import 'widgets/preview_table.dart';
import 'widgets/rule_list_panel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _dragging = false;

  Future<void> _openFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
      withReadStream: false,
    );
    if (result == null || !mounted) return;

    final paths = result.paths.whereType<String>();
    context.read<RenameSession>().addPaths(paths);
  }

  void _onDrop(DropDoneDetails details) {
    final paths = <String>[];
    for (final file in details.files) {
      final path = file.path;
      if (path.isEmpty) continue;
      if (Directory(path).existsSync() && !File(path).existsSync()) continue;
      if (!File(path).existsSync()) continue;
      paths.add(path);
    }
    if (paths.isNotEmpty) {
      context.read<RenameSession>().addPaths(paths);
    }
  }

  Future<void> _confirmAndApply() async {
    final session = context.read<RenameSession>();
    if (!session.canApply) return;

    final count = session.changeCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply renames?'),
        content: Text(
          'Rename $count file${count == 1 ? '' : 's'} on disk?\n'
          'This cannot be undone until Undo is available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await session.applyRenames();
    if (!mounted || result == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.ok
              ? 'Renamed ${result.successCount} file${result.successCount == 1 ? '' : 's'}.'
              : 'Renamed ${result.successCount}, failed ${result.failureCount}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<RenameSession>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (details) {
          setState(() => _dragging = false);
          _onDrop(details);
        },
        child: Column(
          children: [
            _Toolbar(
              canClear: !session.isEmpty,
              canApply: session.canApply,
              isApplying: session.isApplying,
              onOpen: _openFiles,
              onClear: session.clearFiles,
              onApply: _confirmAndApply,
            ),
            if (session.hasPreviewErrors)
              Material(
                color: scheme.errorContainer,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: scheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fix highlighted preview issues before applying.',
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: FileListPanel(onAddFiles: _openFiles),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          flex: 3,
                          child: RuleListPanel(),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          flex: 4,
                          child: PreviewTable(),
                        ),
                      ],
                    ),
                  ),
                  if (_dragging)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            border: Border.all(
                              color: scheme.primary,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Drop files to add',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: scheme.primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.canClear,
    required this.canApply,
    required this.isApplying,
    required this.onOpen,
    required this.onClear,
    required this.onApply,
  });

  final bool canClear;
  final bool canApply;
  final bool isApplying;
  final VoidCallback onOpen;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 1,
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(
              'FileRenamer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilledButton.icon(
                      onPressed: isApplying ? null : onOpen,
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('Open'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: canClear && !isApplying ? onClear : null,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Undo'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: canApply ? onApply : null,
                      icon: isApplying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.drive_file_rename_outline,
                              size: 18),
                      label: Text(isApplying ? 'Applying…' : 'Apply'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
