import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

class RenameMapping {
  const RenameMapping({required this.fromPath, required this.toPath});

  final String fromPath;
  final String toPath;
}

class RenameBatchResult {
  const RenameBatchResult({
    required this.succeeded,
    required this.failed,
  });

  final List<RenameMapping> succeeded;
  final List<RenameFailure> failed;

  bool get ok => failed.isEmpty;
  int get successCount => succeeded.length;
  int get failureCount => failed.length;
}

class RenameFailure {
  const RenameFailure({required this.path, required this.message});

  final String path;
  final String message;
}

/// Performs batch renames with a two-phase strategy to avoid Windows clobbering.
class FileSystemService {
  /// Renames each `fromPath` basename to the matching `newNames` entry.
  Future<RenameBatchResult> renameAll({
    required List<String> fromPaths,
    required List<String> newNames,
  }) async {
    assert(fromPaths.length == newNames.length);

    final plan = <_PlanItem>[];
    for (var i = 0; i < fromPaths.length; i++) {
      final from = p.normalize(fromPaths[i]);
      final to = p.normalize(p.join(p.dirname(from), newNames[i]));
      if (from.toLowerCase() == to.toLowerCase() && from != to) {
        // Case-only change on Windows still needs a rename.
        plan.add(_PlanItem(from: from, to: to));
      } else if (from != to) {
        plan.add(_PlanItem(from: from, to: to));
      }
    }

    if (plan.isEmpty) {
      return const RenameBatchResult(succeeded: [], failed: []);
    }

    final needsTemp = _needsTwoPhase(plan);
    final succeeded = <RenameMapping>[];
    final failed = <RenameFailure>[];

    if (!needsTemp) {
      for (final item in plan) {
        try {
          await File(item.from).rename(item.to);
          succeeded.add(RenameMapping(fromPath: item.from, toPath: item.to));
        } catch (e) {
          failed.add(RenameFailure(path: item.from, message: '$e'));
        }
      }
      return RenameBatchResult(succeeded: succeeded, failed: failed);
    }

    // Phase 1: move to unique temps in the same directory.
    final temps = <_TempHop>[];
    for (final item in plan) {
      try {
        final temp = _uniqueTempPath(item.from);
        await File(item.from).rename(temp);
        temps.add(_TempHop(original: item.from, temp: temp, finalPath: item.to));
      } catch (e) {
        failed.add(RenameFailure(path: item.from, message: '$e'));
        // Roll back temps already moved.
        await _rollbackTemps(temps);
        return RenameBatchResult(succeeded: const [], failed: failed);
      }
    }

    // Phase 2: temps → final names.
    for (final hop in temps) {
      try {
        await File(hop.temp).rename(hop.finalPath);
        succeeded.add(
          RenameMapping(fromPath: hop.original, toPath: hop.finalPath),
        );
      } catch (e) {
        failed.add(RenameFailure(path: hop.original, message: '$e'));
        // Best effort: leave file at temp path rather than lose it.
      }
    }

    return RenameBatchResult(succeeded: succeeded, failed: failed);
  }

  bool _needsTwoPhase(List<_PlanItem> plan) {
    final sources = {
      for (final item in plan) item.from.toLowerCase(),
    };
    for (final item in plan) {
      final targetKey = item.to.toLowerCase();
      if (sources.contains(targetKey) &&
          item.from.toLowerCase() != targetKey) {
        return true;
      }
    }
    // Also use two-phase for any overlapping destination graph.
    final destinations = <String>{};
    for (final item in plan) {
      final key = item.to.toLowerCase();
      if (!destinations.add(key)) return true;
    }
    return false;
  }

  String _uniqueTempPath(String from) {
    final dir = p.dirname(from);
    final rand = Random();
    for (var attempt = 0; attempt < 20; attempt++) {
      final name =
          '.filerenamer_tmp_${DateTime.now().microsecondsSinceEpoch}_${rand.nextInt(1 << 20)}';
      final candidate = p.join(dir, name);
      if (!File(candidate).existsSync() && !Directory(candidate).existsSync()) {
        return candidate;
      }
    }
    throw StateError('Could not allocate temp name near $from');
  }

  Future<void> _rollbackTemps(List<_TempHop> temps) async {
    for (final hop in temps.reversed) {
      try {
        if (File(hop.temp).existsSync()) {
          await File(hop.temp).rename(hop.original);
        }
      } catch (_) {
        // Best effort rollback.
      }
    }
  }
}

class _PlanItem {
  const _PlanItem({required this.from, required this.to});
  final String from;
  final String to;
}

class _TempHop {
  const _TempHop({
    required this.original,
    required this.temp,
    required this.finalPath,
  });
  final String original;
  final String temp;
  final String finalPath;
}
