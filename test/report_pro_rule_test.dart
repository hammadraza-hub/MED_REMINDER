import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/reports/report_pro_rule.dart';

void main() {
  test('7 days or less is free', () {
    expect(ReportProRule.needsPro(1), isFalse);
    expect(ReportProRule.needsPro(7), isFalse);
  });

  test('more than 7 days needs Pro', () {
    expect(ReportProRule.needsPro(8), isTrue);
    expect(ReportProRule.needsPro(30), isTrue);
    expect(ReportProRule.needsPro(365), isTrue);
  });
}
