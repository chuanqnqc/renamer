import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/rename_session.dart';
import 'panel_chrome.dart';

class PreviewTable extends StatelessWidget {
  const PreviewTable({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<RenameSession>();
    final rows = session.preview;
    final errorCount = rows.where((r) => r.hasError).length;
    final changeCount = rows.where((r) => r.willChange).length;

    final subtitle = session.isEmpty
        ? 'Original → New'
        : errorCount > 0
            ? '$errorCount issue${errorCount == 1 ? '' : 's'} · $changeCount changing'
            : '$changeCount of ${rows.length} will change';

    return PanelChrome(
      title: 'Preview',
      subtitle: subtitle,
      child: session.isEmpty
          ? Center(
              child: Text(
                'Live preview of new filenames',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          : Column(
              children: [
                const _HeaderRow(),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final scheme = Theme.of(context).colorScheme;
                      final error = row.hasError;
                      final changed = row.willChange;

                      return ColoredBox(
                        color: error
                            ? scheme.errorContainer.withValues(alpha: 0.35)
                            : Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              if (error)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Tooltip(
                                    message: row.error!,
                                    child: Icon(
                                      Icons.error_outline,
                                      size: 18,
                                      color: scheme.error,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  row.file.originalName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: scheme.outline,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  row.newName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: changed
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: error ? scheme.error : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text('Original', style: labelStyle)),
          const SizedBox(width: 24),
          Expanded(child: Text('New', style: labelStyle)),
        ],
      ),
    );
  }
}
