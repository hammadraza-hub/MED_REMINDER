import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/doctors/doctor_link_diff.dart';

void main() {
  test('nothing changed', () {
    final d = DoctorLinkDiff.compute(
      original: {'a', 'b'},
      selected: {'b', 'a'},
    );
    expect(d.isEmpty, isTrue);
  });

  test('new doctor: everything ticked is linked', () {
    final d = DoctorLinkDiff.compute(original: {}, selected: {'b', 'a'});
    expect(d.toLink, ['a', 'b']);
    expect(d.toUnlink, isEmpty);
  });

  test('edit: some added, some removed, some kept', () {
    final d = DoctorLinkDiff.compute(
      original: {'a', 'b', 'c'},
      selected: {'b', 'd'},
    );
    expect(d.toLink, ['d']);
    expect(d.toUnlink, ['a', 'c']);
    expect(d.isEmpty, isFalse);
  });

  test('everything unticked unlinks all', () {
    final d = DoctorLinkDiff.compute(original: {'x', 'y'}, selected: {});
    expect(d.toLink, isEmpty);
    expect(d.toUnlink, ['x', 'y']);
  });
}
