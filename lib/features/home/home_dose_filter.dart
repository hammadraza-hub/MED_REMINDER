import 'package:flutter/foundation.dart';

import '../../models/dose.dart';

/// The three chips above Home's dose list.
enum HomeFilter {
  all,

  /// Doses still to do: pending, snoozed, and missed ones (a missed dose can
  /// still be marked taken, so it belongs here, not hidden).
  pending,

  taken,
}

class HomeDoseFilter {
  HomeDoseFilter._();

  /// How many times the list was filtered (tests prove a rebuild does not).
  @visibleForTesting
  static int applyCount = 0;

  /// As-needed (PRN) doses are never listed on Home.
  static List<Dose> apply(Iterable<Dose> doses, HomeFilter filter) {
    applyCount++;
    final scheduled = doses.where((d) => !d.isPrn);
    switch (filter) {
      case HomeFilter.all:
        return scheduled.toList();
      case HomeFilter.pending:
        return scheduled
            .where(
              (d) =>
                  d.status == DoseStatus.pending ||
                  d.status == DoseStatus.snoozed ||
                  d.status == DoseStatus.missed,
            )
            .toList();
      case HomeFilter.taken:
        return scheduled.where((d) => d.status == DoseStatus.taken).toList();
    }
  }
}
