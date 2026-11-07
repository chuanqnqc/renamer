import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/rename_rule.dart';
import '../../state/rename_session.dart';
import 'panel_chrome.dart';
import 'rule_card.dart';

class RuleListPanel extends StatefulWidget {
  const RuleListPanel({super.key});

  @override
  State<RuleListPanel> createState() => _RuleListPanelState();
}

class _RuleListPanelState extends State<RuleListPanel> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<RenameSession>();
    final rules = session.rules;

    return PanelChrome(
      title: 'Rules',
      subtitle: rules.isEmpty
          ? 'Drag to reorder · applied top to bottom'
          : '${rules.where((r) => r.enabled).length} of ${rules.length} enabled',
      trailing: PopupMenuButton<String>(
        tooltip: 'Add rule',
        icon: const Icon(Icons.add),
        onSelected: (value) {
          final rule = _createRule(value);
          if (rule == null) return;
          session.addRule(rule);
          setState(() => _expandedId = rule.id);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'prefix', child: Text('Prefix')),
          PopupMenuItem(value: 'suffix', child: Text('Suffix')),
          PopupMenuItem(value: 'findReplace', child: Text('Find & replace')),
          PopupMenuItem(value: 'removeChars', child: Text('Remove characters')),
          PopupMenuItem(
            value: 'insertAtPosition',
            child: Text('Insert at position'),
          ),
          PopupMenuItem(value: 'clearName', child: Text('Clear name')),
          PopupMenuItem(value: 'nameCase', child: Text('Name case')),
          PopupMenuDivider(),
          PopupMenuItem(value: 'numbering', child: Text('Numbering')),
          PopupMenuItem(value: 'insertDate', child: Text('Insert date')),
          PopupMenuItem(value: 'extensionCase', child: Text('Extension case')),
        ],
      ),
      child: rules.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Add rules to transform filenames.\n'
                  'They run top to bottom — drag to reorder.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: rules.length,
              onReorderItem: session.reorderRules,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return RuleCard(
                  key: ValueKey(rule.id),
                  index: index,
                  rule: rule,
                  expanded: _expandedId == rule.id,
                  onExpandedChanged: (open) {
                    setState(() => _expandedId = open ? rule.id : null);
                  },
                );
              },
            ),
    );
  }

  RenameRule? _createRule(String value) {
    return switch (value) {
      'prefix' => RenameRuleFactory.prefix(),
      'suffix' => RenameRuleFactory.suffix(),
      'findReplace' => RenameRuleFactory.findReplace(),
      'removeChars' => RenameRuleFactory.removeChars(),
      'insertAtPosition' => RenameRuleFactory.insertAtPosition(),
      'clearName' => RenameRuleFactory.clearName(),
      'nameCase' => RenameRuleFactory.nameCase(),
      'numbering' => RenameRuleFactory.numbering(),
      'insertDate' => RenameRuleFactory.insertDate(),
      'extensionCase' => RenameRuleFactory.extensionCase(),
      _ => null,
    };
  }
}
