// M18 step 5 - talks to the REAL api.fda.gov. Skipped unless asked:
//   flutter test test/fda_label_live_test.dart --dart-define=FDA_LIVE=true
// (needs internet; uses 2 of the 1000 free requests a day.)
import 'package:flutter_test/flutter_test.dart';
import 'package:med_remind_app/core/ai/fda_label.dart';
import 'package:med_remind_app/core/ai/fda_label_client.dart';

const bool live = bool.fromEnvironment('FDA_LIVE');

void main() {
  test(
    'Metformin: the catalogue ingredient id has no label, the name finds it',
    () async {
      final c = FdaLabelClient();
      final r = await c.lookup(rxcui: '6809', name: 'Metformin');
      expect(r, isA<FdaLabelFound>());
      final label = (r as FdaLabelFound).label;
      expect(
        label.sections.containsKey(FdaLabelSection.adverseReactions),
        isTrue,
      );
      expect(label.sourceUrl, startsWith('https://dailymed.nlm.nih.gov/'));
      // Not a combination product such as sitagliptin + metformin.
      expect(label.genericName!.toLowerCase(), contains('metformin'));
      expect(label.genericName!.toLowerCase(), isNot(contains('sitagliptin')));
    },
    skip: live ? false : 'set --dart-define=FDA_LIVE=true to run',
  );

  test('a medicine that does not exist has no label', () async {
    final r = await FdaLabelClient().lookup(name: 'Zzxqwy');
    expect(r, isA<FdaLabelNotFound>());
  }, skip: live ? false : 'set --dart-define=FDA_LIVE=true to run');
}
