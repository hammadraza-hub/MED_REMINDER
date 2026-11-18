import 'package:flutter/material.dart';

/// The time of a dose as the person's phone writes it: 12 or 24 hours by the
/// phone's setting, and the digits / AM-PM of the app language. (It used to be
/// built by hand as "8:30 AM" in two places, in English only.)
String formatDoseTimeWith(
  MaterialLocalizations localizations,
  DateTime at, {
  required bool use24Hour,
}) {
  return localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(at.toLocal()),
    alwaysUse24HourFormat: use24Hour,
  );
}

String formatDoseTime(BuildContext context, DateTime at) {
  return formatDoseTimeWith(
    MaterialLocalizations.of(context),
    at,
    use24Hour: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}
