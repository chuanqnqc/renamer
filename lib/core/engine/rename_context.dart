/// Per-file context passed through the rule pipeline.
class RenameContext {
  RenameContext({
    required this.index,
    required this.total,
    required this.originalName,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  final int index;
  final int total;
  final String originalName;

  /// Wall clock used by date rules (injectable for tests).
  final DateTime now;

  int get oneBasedIndex => index + 1;
}
