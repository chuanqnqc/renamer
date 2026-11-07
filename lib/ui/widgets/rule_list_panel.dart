import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/rename_rule.dart';
import '../../state/rename_session.dart';
import 'panel_chrome.dart';
import 'rule_card.dart';

class RuleListPanel extends StatelessWidget {
  const RuleListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<RenameSession>();
    final rules = session.rules;

    return PanelChrome(
      title: 'Rules',
      subtitle: rules.isEmpty
          ? 'Applied in order'
          : '${rules.where((r) => r.enabled).length} of ${rules.length} enabled',
      trailing: PopupMenuButton<String>(
        tooltip: 'Add rule',
        icon: const Icon(Icons.add),
        onSelected: (value) {
          final rule = _createRule(value);
          if (rule != null) session.addRule(rule);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'prefix', child: Text('Prefix')),
          PopupMenuItem(value: 'suffix', child: Text('Suffix')),
          PopupMenuItem(value: 'findReplace', child: Text('Find & replace')),
          PopupMenuItem(value: 'removeChars', child: Text('Remove characters')),
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
                  'They run top to bottom.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          : ListView.builder(
              itemCount: rules.length,
              itemBuilder: (context, index) => RuleCard(
                index: index,
                rule: rules[index],
              ),
            ),
    );
  }

  RenameRule? _createRule(String value) {
    return switch (value) {
      'prefix' => RenameRuleFactory.prefix(),
      'suffix' => RenameRuleFactory.suffix(),
      'findReplace' => RenameRuleFactory.findReplace(),
      'removeChars' => RenameRuleFactory.removeChars(),
      'nameCase' => RenameRuleFactory.nameCase(),
      'numbering' => RenameRuleFactory.numbering(),
      'insertDate' => RenameRuleFactory.insertDate(),
      'extensionCase' => RenameRuleFactory.extensionCase(),
      _ => null,
    };
  }
}
