import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/constant/liquid_document_type.dart';
import 'package:module_liquid/data/models/ocr_result.dart';
import 'package:module_liquid/persentation/views/screens/ordering_information_screen.dart';

/// Audit a11y form Ordering Information (WCAG 2.2 AA).
///
/// Fokus: input wajib punya label semantik (bukan cuma visual), tombol
/// kalender bisa diakses keyboard, dan penanda wajib terbaca screen reader.
void main() {
  group('Ordering Information - accessibility', () {
    testWidgets('input punya semantic label + penanda wajib', (tester) async {
      final handle = tester.ensureSemantics();
      _useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // TextFormField urut: [0] no kartu, [1..3] expired, [4..6] permission
      // to land, [7..9] period to stay, [10] nama, [11..13] tanggal lahir,
      // [14] kode pos, [15..17] alamat 1-3.
      expect(_label(tester, find.byType(TextFormField).at(0)),
          contains('Residence Card Number, required'));
      expect(_label(tester, find.byType(TextFormField).at(10)),
          contains('Ordering Customer Name (ENGLISH), required'));
      expect(_label(tester, find.byType(TextFormField).at(15)),
          contains('Address 1 Town / City, required'));
      // Field opsional → tanpa penanda "required".
      expect(_label(tester, find.byType(TextFormField).at(17)),
          contains('Address 3 Building / Room No'));
      expect(_label(tester, find.byType(TextFormField).at(17)),
          isNot(contains('required')));

      handle.dispose();
    });

    testWidgets('kotak tanggal punya label per bagian', (tester) async {
      final handle = tester.ensureSemantics();
      _useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(_label(tester, find.byType(TextFormField).at(1)),
          contains('Expired Date year'));
      expect(_label(tester, find.byType(TextFormField).at(2)),
          contains('Expired Date month'));
      expect(_label(tester, find.byType(TextFormField).at(3)),
          contains('Expired Date day'));

      handle.dispose();
    });

    testWidgets('dropdown punya semantic label', (tester) async {
      final handle = tester.ensureSemantics();
      _useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      expect(_label(tester, dropdowns.at(0)), contains('Nationality, required'));
      expect(_label(tester, dropdowns.at(1)), contains('Visa Status, required'));

      handle.dispose();
    });

    testWidgets('kalender itu tombol bener (bisa keyboard & tooltip)',
        (tester) async {
      _useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // 4 field tanggal → 4 tombol kalender, semuanya punya tooltip.
      expect(find.byTooltip('Pilih tanggal'), findsNWidgets(4));

      final buttons = tester.widgetList<IconButton>(
        find.widgetWithIcon(IconButton, Icons.calendar_month),
      );
      expect(buttons, hasLength(4));
    });

    testWidgets('tombol kalender bisa diaktifkan', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_month).first);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarDatePicker), findsOneWidget);
    });
  });
}

/// Viewport tinggi biar semua field kebikin (ListView cuma build yang
/// kelihatan).
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Label semantik dari node yang menaungi [finder].
String _label(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).label;

Widget _wrap() {
  return MaterialApp(
    home: OrderingInformationScreen(
      documentType: LiquidDocumentType.residenceCard,
      sdkOcr: OcrResult(idNumber: 'UH36759361EA', nationality: 'id'),
    ),
  );
}
