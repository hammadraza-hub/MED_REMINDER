import 'package:flutter_test/flutter_test.dart';

import 'package:med_remind_app/main.dart';

void main() {
  testWidgets('App build hoti hai', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
