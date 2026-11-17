import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/app/app.dart';

void main() {
  testWidgets('Liquid eKYC app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LiquidEkycApp());
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan Verifikasi'), findsOneWidget);
    expect(find.text('Pilih Dokumen'), findsOneWidget);
  });
}