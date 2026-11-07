import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/models/rename_rule.dart';
import '../../state/rename_session.dart';

class RuleCard extends StatelessWidget {
  const RuleCard({
    super.key,
    required this.index,
    required this.rule,
  });

  final int index;
  final RenameRule rule;

  @override
  Widget build(BuildContext context) {
    final session = context.read<RenameSession>();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      elevation: 0,
      color: rule.enabled
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Checkbox(
                  value: rule.enabled,
                  onChanged: (v) =>
                      session.setRuleEnabled(index, v ?? false),
                ),
                Expanded(
                  child: Text(
                    rule.typeLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: rule.enabled
                              ? null
                              : scheme.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove rule',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => session.removeRuleAt(index),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: _RuleEditor(rule: rule),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleEditor extends StatelessWidget {
  const _RuleEditor({required this.rule});

  final RenameRule rule;

  @override
  Widget build(BuildContext context) {
    final session = context.read<RenameSession>();
    void touch() => session.touchRules();

    return switch (rule) {
      final PrefixRule r => _TextField(
          label: 'Prefix',
          value: r.prefix,
          onChanged: (v) {
            r.prefix = v;
            touch();
          },
        ),
      final SuffixRule r => _TextField(
          label: 'Suffix',
          value: r.suffix,
          onChanged: (v) {
            r.suffix = v;
            touch();
          },
        ),
      final FindReplaceRule r => Column(
          children: [
            _TextField(
              label: 'Find',
              value: r.find,
              onChanged: (v) {
                r.find = v;
                touch();
              },
            ),
            const SizedBox(height: 8),
            _TextField(
              label: 'Replace',
              value: r.replace,
              onChanged: (v) {
                r.replace = v;
                touch();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Case sensitive'),
              value: r.caseSensitive,
              onChanged: (v) {
                r.caseSensitive = v;
                touch();
              },
            ),
          ],
        ),
      final RemoveCharsRule r => Row(
          children: [
            Expanded(
              child: _IntField(
                label: 'Count',
                value: r.count,
                min: 0,
                onChanged: (v) {
                  r.count = v;
                  touch();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<CharRemoveFrom>(
                // ignore: deprecated_member_use
                value: r.from,
                decoration: const InputDecoration(
                  labelText: 'From',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: CharRemoveFrom.start,
                    child: Text('Start'),
                  ),
                  DropdownMenuItem(
                    value: CharRemoveFrom.end,
                    child: Text('End'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  r.from = v;
                  touch();
                },
              ),
            ),
          ],
        ),
      final NameCaseRule r => DropdownButtonFormField<NameCaseMode>(
          // ignore: deprecated_member_use
          value: r.mode,
          decoration: const InputDecoration(
            labelText: 'Case',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: NameCaseMode.lower, child: Text('lowercase')),
            DropdownMenuItem(value: NameCaseMode.upper, child: Text('UPPERCASE')),
            DropdownMenuItem(value: NameCaseMode.title, child: Text('Title Case')),
            DropdownMenuItem(value: NameCaseMode.camel, child: Text('camelCase')),
          ],
          onChanged: (v) {
            if (v == null) return;
            r.mode = v;
            touch();
          },
        ),
      final NumberingRule r => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _IntField(
                    label: 'Start',
                    value: r.start,
                    onChanged: (v) {
                      r.start = v;
                      touch();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _IntField(
                    label: 'Step',
                    value: r.step,
                    onChanged: (v) {
                      r.step = v;
                      touch();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _IntField(
                    label: 'Pad',
                    value: r.pad,
                    min: 0,
                    onChanged: (v) {
                      r.pad = v;
                      touch();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<InsertPosition>(
                    // ignore: deprecated_member_use
                    value: r.position,
                    decoration: const InputDecoration(
                      labelText: 'Position',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: InsertPosition.start,
                        child: Text('Start'),
                      ),
                      DropdownMenuItem(
                        value: InsertPosition.end,
                        child: Text('End'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      r.position = v;
                      touch();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _TextField(
              label: 'Separator',
              value: r.separator,
              onChanged: (v) {
                r.separator = v;
                touch();
              },
            ),
          ],
        ),
      final InsertDateRule r => Column(
          children: [
            _TextField(
              label: 'Pattern',
              value: r.pattern,
              onChanged: (v) {
                r.pattern = v;
                touch();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<InsertPosition>(
                    // ignore: deprecated_member_use
                    value: r.position,
                    decoration: const InputDecoration(
                      labelText: 'Position',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: InsertPosition.start,
                        child: Text('Start'),
                      ),
                      DropdownMenuItem(
                        value: InsertPosition.end,
                        child: Text('End'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      r.position = v;
                      touch();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TextField(
                    label: 'Separator',
                    value: r.separator,
                    onChanged: (v) {
                      r.separator = v;
                      touch();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      final ExtensionCaseRule r => DropdownButtonFormField<ExtensionCaseMode>(
          // ignore: deprecated_member_use
          value: r.mode,
          decoration: const InputDecoration(
            labelText: 'Extension case',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: ExtensionCaseMode.lower,
              child: Text('lowercase'),
            ),
            DropdownMenuItem(
              value: ExtensionCaseMode.upper,
              child: Text('UPPERCASE'),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            r.mode = v;
            touch();
          },
        ),
    };
  }
}

class _TextField extends StatefulWidget {
  const _TextField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _IntField extends StatefulWidget {
  const _IntField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int? min;

  @override
  State<_IntField> createState() => _IntFieldState();
}

class _IntFieldState extends State<_IntField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant _IntField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = '${widget.value}';
    if (text != _controller.text) {
      _controller.text = text;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (raw) {
        final parsed = int.tryParse(raw);
        if (parsed == null) return;
        final min = widget.min;
        widget.onChanged(min != null && parsed < min ? min : parsed);
      },
    );
  }
}
