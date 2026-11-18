import 'package:flutter/foundation.dart';

import '../../models/dose.dart';

/// The numbers in Home's progress card, computed ONCE per change of the dose
/// list (and when time makes a dose late), not on every rebuild.
///
///  * as-needed (PRN) doses are not counted;
///  * a pending or snoozed dose is "missed" once its miss deadline has passed
///    (before, such a dose was counted twice: as pending and as missed), and
///    "pending" before that;
///  * skipped doses are neither (they were a decision, not a to-do).
@immutable
class HomeSummary {
  const HomeSummary({
    required this.taken,
    required this.pending,
    required this.missed,
  });

  static const HomeSummary empty = HomeSummary(taken: 0, pending: 0, missed: 0);

  final int taken;
  final int pending;
  final int missed;

  /// How many times a summary was computed (tests use it to prove that a
  /// rebuild does not recompute).
  @visibleForTesting
  static int computeCount = 0;

  static HomeSummary of(Iterable<Dose> doses, {DateTime? now}) {
    computeCount++;
    final at = (now ?? DateTime.now()).toUtc();
    var taken = 0, pending = 0, missed = 0;
    for (final d in doses) {
      if (d.isPrn) continue;
      switch (d.status) {
        case DoseStatus.taken:
          taken++;
        case DoseStatus.missed:
          missed++;
        case DoseStatus.pending:
        case DoseStatus.snoozed:
          if (d.missDeadline.toUtc().isBefore(at)) {
            missed++;
          } else {
            pending++;
          }
        case DoseStatus.skipped:
          break;
      }
    }
    return HomeSummary(taken: taken, pending: pending, missed: missed);
  }

  int get total => taken + pending + missed;

  /// 0.0 .. 1.0; 0 when there is nothing to take.
  double get progress => total == 0 ? 0.0 : taken / total;

  @override
  bool operator ==(Object other) =>
      other is HomeSummary &&
      other.taken == taken &&
      other.pending == pending &&
      other.missed == missed;

  @override
  int get hashCode => Object.hash(taken, pending, missed);

  @override
  String toString() =>
      'HomeSummary($taken taken, $pending pending, $missed missed)';
}
