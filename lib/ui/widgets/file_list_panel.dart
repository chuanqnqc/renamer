import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/rename_session.dart';
import 'panel_chrome.dart';

class FileListPanel extends StatelessWidget {
  const FileListPanel({
    super.key,
    required this.onAddFiles,
    required this.onAddFolder,
  });

  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<RenameSession>();

    return PanelChrome(
      title: 'Files',
      subtitle: session.isEmpty
          ? 'Drop or select files to begin'
          : '${session.fileCount} selected',
      trailing: PopupMenuButton<String>(
        tooltip: 'Add',
        icon: const Icon(Icons.add),
        onSelected: (value) {
          switch (value) {
            case 'files':
              onAddFiles();
            case 'folder':
              onAddFolder();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'files', child: Text('Add files')),
          PopupMenuItem(value: 'folder', child: Text('Add folder')),
        ],
      ),
      child: session.isEmpty
          ? _EmptyHint(onAddFiles: onAddFiles, onAddFolder: onAddFolder)
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
  const _EmptyHint({
    required this.onAddFiles,
    required this.onAddFolder,
  });

  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upload_file,
              size: 56,
              color: scheme.primary.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              'drag or select your files here',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onAddFiles,
                  icon: const Icon(Icons.insert_drive_file_outlined, size: 18),
                  label: const Text('Select files'),
                ),
                OutlinedButton.icon(
                  onPressed: onAddFolder,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Open folder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
