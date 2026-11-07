import 'package:intl/intl.dart';

import '../engine/filename_parts.dart';
import '../engine/rename_context.dart';

enum NameCaseMode { lower, upper, title, camel }

enum CharRemoveFrom { start, end }

enum InsertPosition { start, end }

enum ExtensionCaseMode { lower, upper }

/// Ordered rename transform. Disabled rules are skipped by [RuleEngine].
sealed class RenameRule {
  RenameRule({
    required this.id,
    this.enabled = true,
  });

  final String id;
  bool enabled;

  String get typeLabel;
  String get summary;

  String apply(String name, RenameContext ctx);

  RenameRule copy();
}

class PrefixRule extends RenameRule {
  PrefixRule({
    required super.id,
    super.enabled,
    this.prefix = '',
  });

  String prefix;

  @override
  String get typeLabel => 'Prefix';

  @override
  String get summary =>
      prefix.isEmpty ? 'Add prefix' : 'Add prefix "$prefix"';

  @override
  String apply(String name, RenameContext ctx) {
    final parts = FilenameParts.parse(name);
    return parts.copyWith(stem: '$prefix${parts.stem}').fullName;
  }

  @override
  PrefixRule copy() =>
      PrefixRule(id: id, enabled: enabled, prefix: prefix);
}

class SuffixRule extends RenameRule {
  SuffixRule({
    required super.id,
    super.enabled,
    this.suffix = '',
  });

  String suffix;

  @override
  String get typeLabel => 'Suffix';

  @override
  String get summary =>
      suffix.isEmpty ? 'Add suffix' : 'Add suffix "$suffix"';

  @override
  String apply(String name, RenameContext ctx) {
    final parts = FilenameParts.parse(name);
    return parts.copyWith(stem: '${parts.stem}$suffix').fullName;
  }

  @override
  SuffixRule copy() =>
      SuffixRule(id: id, enabled: enabled, suffix: suffix);
}

class FindReplaceRule extends RenameRule {
  FindReplaceRule({
    required super.id,
    super.enabled,
    this.find = '',
    this.replace = '',
    this.caseSensitive = true,
  });

  String find;
  String replace;
  bool caseSensitive;

  @override
  String get typeLabel => 'Find & replace';

  @override
  String get summary {
    if (find.isEmpty) return 'Find & replace';
    return 'Replace "$find" → "$replace"';
  }

  @override
  String apply(String name, RenameContext ctx) {
    if (find.isEmpty) return name;
    if (caseSensitive) {
      return name.replaceAll(find, replace);
    }
    final pattern = RegExp(RegExp.escape(find), caseSensitive: false);
    return name.replaceAll(pattern, replace);
  }

  @override
  FindReplaceRule copy() => FindReplaceRule(
        id: id,
        enabled: enabled,
        find: find,
        replace: replace,
        caseSensitive: caseSensitive,
      );
}

class RemoveCharsRule extends RenameRule {
  RemoveCharsRule({
    required super.id,
    super.enabled,
    this.count = 1,
    this.from = CharRemoveFrom.start,
  });

  int count;
  CharRemoveFrom from;

  @override
  String get typeLabel => 'Remove characters';

  @override
  String get summary {
    final side = from == CharRemoveFrom.start ? 'start' : 'end';
    return 'Remove $count from $side';
  }

  @override
  String apply(String name, RenameContext ctx) {
    final parts = FilenameParts.parse(name);
    final n = count < 0 ? 0 : count;
    if (n == 0 || parts.stem.isEmpty) return name;

    final stem = switch (from) {
      CharRemoveFrom.start =>
        parts.stem.length <= n ? '' : parts.stem.substring(n),
      CharRemoveFrom.end => parts.stem.length <= n
          ? ''
          : parts.stem.substring(0, parts.stem.length - n),
    };
    return parts.copyWith(stem: stem).fullName;
  }

  @override
  RemoveCharsRule copy() => RemoveCharsRule(
        id: id,
        enabled: enabled,
        count: count,
        from: from,
      );
}

class NameCaseRule extends RenameRule {
  NameCaseRule({
    required super.id,
    super.enabled,
    this.mode = NameCaseMode.lower,
  });

  NameCaseMode mode;

  @override
  String get typeLabel => 'Name case';

  @override
  String get summary => switch (mode) {
        NameCaseMode.lower => 'Name → lowercase',
        NameCaseMode.upper => 'Name → UPPERCASE',
        NameCaseMode.title => 'Name → Title Case',
        NameCaseMode.camel => 'Name → camelCase',
      };

  @override
  String apply(String name, RenameContext ctx) {
    final parts = FilenameParts.parse(name);
    return parts.copyWith(stem: _transform(parts.stem)).fullName;
  }

  String _transform(String stem) {
    switch (mode) {
      case NameCaseMode.lower:
        return stem.toLowerCase();
      case NameCaseMode.upper:
        return stem.toUpperCase();
      case NameCaseMode.title:
        return stem
            .split(RegExp(r'[\s_]+'))
            .where((w) => w.isNotEmpty)
            .map((w) =>
                '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
      case NameCaseMode.camel:
        final words = stem
            .split(RegExp(r'[\s_\-]+'))
            .where((w) => w.isNotEmpty)
            .toList();
        if (words.isEmpty) return stem;
        final first = words.first.toLowerCase();
        final rest = words.skip(1).map((w) =>
            '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}');
        return ([first, ...rest]).join();
    }
  }

  @override
  NameCaseRule copy() =>
      NameCaseRule(id: id, enabled: enabled, mode: mode);
}

class NumberingRule extends RenameRule {
  NumberingRule({
    required super.id,
    super.enabled,
    this.start = 1,
    this.step = 1,
    this.pad = 0,
    this.position = InsertPosition.start,
    this.separator = '_',
  });

  int start;
  int step;
  int pad;
  InsertPosition position;
  String separator;

  @override
  String get typeLabel => 'Numbering';

  @override
  String get summary {
    final side = position == InsertPosition.start ? 'start' : 'end';
    final padInfo = pad > 0 ? ', pad $pad' : '';
    return 'Number from $start step $step at $side$padInfo';
  }

  @override
  String apply(String name, RenameContext ctx) {
    final value = start + ctx.index * step;
    final token = pad > 0
        ? value.toString().padLeft(pad, '0')
        : value.toString();
    final parts = FilenameParts.parse(name);
    final stem = switch (position) {
      InsertPosition.start => '$token$separator${parts.stem}',
      InsertPosition.end => '${parts.stem}$separator$token',
    };
    return parts.copyWith(stem: stem).fullName;
  }

  @override
  NumberingRule copy() => NumberingRule(
        id: id,
        enabled: enabled,
        start: start,
        step: step,
        pad: pad,
        position: position,
        separator: separator,
      );
}

class InsertDateRule extends RenameRule {
  InsertDateRule({
    required super.id,
    super.enabled,
    this.pattern = 'yyyy-MM-dd',
    this.position = InsertPosition.start,
    this.separator = '_',
  });

  String pattern;
  InsertPosition position;
  String separator;

  @override
  String get typeLabel => 'Insert date';

  @override
  String get summary {
    final side = position == InsertPosition.start ? 'start' : 'end';
    return 'Insert date ($pattern) at $side';
  }

  @override
  String apply(String name, RenameContext ctx) {
    final formatted = _format(ctx.now);
    final parts = FilenameParts.parse(name);
    final stem = switch (position) {
      InsertPosition.start => '$formatted$separator${parts.stem}',
      InsertPosition.end => '${parts.stem}$separator$formatted',
    };
    return parts.copyWith(stem: stem).fullName;
  }

  String _format(DateTime now) {
    try {
      return DateFormat(pattern).format(now);
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(now);
    }
  }

  @override
  InsertDateRule copy() => InsertDateRule(
        id: id,
        enabled: enabled,
        pattern: pattern,
        position: position,
        separator: separator,
      );
}

class ExtensionCaseRule extends RenameRule {
  ExtensionCaseRule({
    required super.id,
    super.enabled,
    this.mode = ExtensionCaseMode.lower,
  });

  ExtensionCaseMode mode;

  @override
  String get typeLabel => 'Extension case';

  @override
  String get summary => switch (mode) {
        ExtensionCaseMode.lower => 'Extension → lowercase',
        ExtensionCaseMode.upper => 'Extension → UPPERCASE',
      };

  @override
  String apply(String name, RenameContext ctx) {
    final parts = FilenameParts.parse(name);
    if (parts.extension.isEmpty) return name;
    final ext = switch (mode) {
      ExtensionCaseMode.lower => parts.extension.toLowerCase(),
      ExtensionCaseMode.upper => parts.extension.toUpperCase(),
    };
    return parts.copyWith(extension: ext).fullName;
  }

  @override
  ExtensionCaseRule copy() =>
      ExtensionCaseRule(id: id, enabled: enabled, mode: mode);
}

/// Factory helpers for the Add Rule menu.
abstract final class RenameRuleFactory {
  static int _seq = 0;

  static String newId() {
    _seq += 1;
    return 'rule_${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }

  static PrefixRule prefix() => PrefixRule(id: newId());
  static SuffixRule suffix() => SuffixRule(id: newId());
  static FindReplaceRule findReplace() => FindReplaceRule(id: newId());
  static RemoveCharsRule removeChars() => RemoveCharsRule(id: newId());
  static NameCaseRule nameCase() => NameCaseRule(id: newId());
  static NumberingRule numbering() => NumberingRule(id: newId());
  static InsertDateRule insertDate() => InsertDateRule(id: newId());
  static ExtensionCaseRule extensionCase() =>
      ExtensionCaseRule(id: newId());
}
