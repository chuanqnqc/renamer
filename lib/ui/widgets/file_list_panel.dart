import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/rename_session.dart';
import 'panel_chrome.dart';

class FileListPanel extends StatelessWidget {
  const FileListPanel({super.key, required this.onAddFiles});

  final VoidCallback onAddFiles;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<RenameSession>();

    return PanelChrome(
      title: 'Files',
      subtitle: session.isEmpty
          ? 'Drop or open files to begin'
          : '${session.fileCount} selected',
      trailing: IconButton(
        tooltip: 'Add files',
        onPressed: onAddFiles,
        icon: const Icon(Icons.add),
      ),
      child: session.isEmpty
          ? _EmptyHint(onAddFiles: onAddFiles)
          : ListView.separated(
              itemCount: session.files.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final file = session.files[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(
                    file.originalName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    file.directory,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => session.removeAt(index),
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.onAddFiles});

  final VoidCallback onAddFiles;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_open_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Drag files here or choose Open',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAddFiles,
              child: const Text('Browse files'),
            ),
          ],
        ),
      ),
    );
  }
}
