import 'package:flutter_test/flutter_test.dart';
import 'package:poc_liquidekyc_flutter/app/app.dart';

void main() {
  testWidgets('Liquid eKYC app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LiquidEkycApp());
    await tester.pumpAndSettle();
    expect(find.text('eKYC Verification'), findsOneWidget);
  });
}