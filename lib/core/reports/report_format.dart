import 'report_range.dart';

/// Number and date formats shared by the CSV and the PDF, so both always show
/// a value the same way. M17 step 4.
class ReportFormat {
  ReportFormat._();

  /// Up to 2 decimals, `.` as the separator, no trailing zeros: 90, 98.6, 72.46.
  static String dec(double v) {
    var s = v.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s == '-0' ? '0' : s;
  }

  /// `yyyy-MM-dd HH:mm` in local time.
  static String dateTime(DateTime t) {
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${ReportRange.dayKey(l)} ${two(l.hour)}:${two(l.minute)}';
  }

  /// `MM-dd` of a `yyyy-MM-dd` day key (short axis labels).
  static String shortDay(String dayKey) =>
      dayKey.length >= 10 ? dayKey.substring(5) : dayKey;
}
