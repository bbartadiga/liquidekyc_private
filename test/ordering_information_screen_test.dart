import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/constant/liquid_document_type.dart';
import 'package:module_liquid/data/models/chip_data.dart';
import 'package:module_liquid/data/models/id_document_information_response.dart';
import 'package:module_liquid/data/models/processed_information_response.dart';
import 'package:module_liquid/data/models/ocr_result.dart';
import 'package:module_liquid/persentation/views/screens/ordering_information_screen.dart';

void main() {
  group('OrderingInformationScreen', () {
    testWidgets('menampilkan semua field sesuai mockup', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Ordering Information'), findsOneWidget);
      expect(find.text('Residence Card Number *'), findsOneWidget);
      expect(find.text('Expired Date *'), findsOneWidget);
      expect(find.text('Nationality *'), findsOneWidget);
      expect(find.text('Visa Status *'), findsOneWidget);
      expect(find.text('Permission to Land *'), findsOneWidget);
      expect(find.text('Period to Stay'), findsOneWidget);
    });

    testWidgets('field lanjutan tampil sesuai mockup', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Ordering Customer Name (ENGLISH) *'), findsOneWidget);
      expect(find.text('Date of Birth *'), findsOneWidget);
      expect(find.text('Gender *'), findsOneWidget);
      expect(find.text('Postal Code *'), findsOneWidget);
      expect(find.text('Address 1 Town / City *'), findsOneWidget);
      expect(find.text('Address 2 Street or other details *'), findsOneWidget);
      expect(find.text('Address 3 Building / Room No'), findsOneWidget);
    });

    testWidgets('field terisi dari data OCR / IC chip', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('ZO254207410B'), findsOneWidget);
      expect(find.text('Indonesian'), findsOneWidget);
      expect(find.text('PERMANENT RESIDENT'), findsOneWidget);
      // 2030 (expired) + 2025 (permission to land) + 2030 (period to stay)
      expect(find.text('2030'), findsNWidgets(2));
      expect(find.text('2025'), findsOneWidget);
    });

    testWidgets('nama ENGLISH, gender, dan tanggal lahir terisi dari chip',
        (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: OrderingInformationScreen(
            chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
              'nameKana': 'ほうむしょう',
              'birthday': '19980215',
              'sex': 'FEMALE',
              'zipCode': '1000001',
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('02: FEMALE'), findsOneWidget);
      expect(find.text('1998'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('1000001'), findsOneWidget);
    });

    testWidgets('field residence disembunyiin buat nationality Japan',
        (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(_wrap(withData: false, nationality: 'jp'));
      await tester.pumpAndSettle();

      expect(find.text('Visa Status *'), findsNothing);
      expect(find.text('Permission to Land *'), findsNothing);
      expect(find.text('Period to Stay'), findsNothing);
    });

    testWidgets('field residence muncul buat nationality Indonesian',
        (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(_wrap(withData: false, nationality: 'id'));
      await tester.pumpAndSettle();

      expect(find.text('Visa Status *'), findsOneWidget);
      expect(find.text('Permission to Land *'), findsOneWidget);
      expect(find.text('Period to Stay'), findsOneWidget);
    });

    testWidgets('judul field nomor kartu ikut jenis dokumen', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(
        _wrap(documentType: LiquidDocumentType.driverLicense),
      );
      await tester.pumpAndSettle();
      expect(find.text("Driver's License Number *"), findsOneWidget);
    });

    testWidgets('judul field nomor kartu buat My Number Card', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(
        _wrap(documentType: LiquidDocumentType.myNumberCard),
      );
      await tester.pumpAndSettle();
      expect(find.text('My Number Card Number *'), findsOneWidget);
    });

    testWidgets('field visa status muncul kalo nationality Indonesia',
        (tester) async {
      _useTallViewport(tester);

      // Kartu nggak nyediain kebangsaan → pakai pilihan awal (Indonesia).
      await tester.pumpWidget(
        MaterialApp(
          home: OrderingInformationScreen(
            documentType: LiquidDocumentType.residenceCard,
            initialNationality: 'Indonesian',
            sdkOcr: OcrResult(idNumber: 'UH36759361EA'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visa Status *'), findsOneWidget);
      expect(find.text('Permission to Land *'), findsOneWidget);
      expect(find.text('Period to Stay'), findsOneWidget);
    });

    testWidgets('field visa status disembunyiin kalo nationality bukan Indonesia',
        (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: OrderingInformationScreen(
            documentType: LiquidDocumentType.driverLicense,
            initialNationality: 'Japanese',
            sdkOcr: OcrResult(idNumber: '302302005100'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visa Status *'), findsNothing);
      expect(find.text('Permission to Land *'), findsNothing);
      expect(find.text('Period to Stay'), findsNothing);
      // Field umum tetap tampil.
      expect(find.text('Nationality *'), findsOneWidget);
      expect(find.text('Date of Birth *'), findsOneWidget);
    });

    testWidgets('form nampilin data dari API 007 & 027', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: OrderingInformationScreen(
            documentType: LiquidDocumentType.residenceCard,
            initialNationality: 'Indonesian',
            idDocumentInformation: IdDocumentInformationResponse(
              isSuccess: true,
              stayExpireDate: '20300709',
              residentStatus: '永住者',
            ),
            processedInformation: ProcessedInformationResponse.fromMap({
              'latin_name': {
                'is_available': true,
                'last_name': 'dhika',
                'first_name': 'pratama',
              },
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nama latin dari API 027.
      expect(find.text('DHIKA PRATAMA'), findsOneWidget);
      // Period to Stay + Visa Status dari API 007.
      expect(find.text('2030'), findsOneWidget);
      expect(find.text('PERMANENT RESIDENT'), findsOneWidget);
      // Badge sumbernya nunjukin API yang dipakai.
      expect(find.text('BE 027'), findsOneWidget);
      expect(find.text('BE 007'), findsWidgets);
    });

    testWidgets('field alamat multi-line & punya batas karakter', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(
        _wrap(
          withData: false,
          sdkOcrExtra: OcrResult(
            address: '東京都品川区上大崎2丁目10番11号 アビティ目黒 401',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Alamat panjang harus nampil utuh (multi-line), bukan kepotong.
      expect(
        find.text('東京都品川区上大崎2丁目10番11号 アビティ目黒 401'),
        findsOneWidget,
      );

      final addressField = find.byWidgetPredicate(
        (w) =>
            w is EditableText &&
            w.controller.text.contains('東京都品川区'),
      );
      final addressEditable = tester.widget<EditableText>(addressField);
      expect(
        addressEditable.maxLines,
        3,
        reason: 'field alamat harus multi-line biar teks panjang nggak kepotong',
      );

      // Batas 300 char (spec 016 hal. 6) → input dibatasi, bukan dipotong diam-diam.
      await tester.enterText(addressField, 'x' * 350);
      await tester.pumpAndSettle();
      expect(addressEditable.controller.text.length, 300);
    });

    testWidgets('badge sumber data muncul di field yang terisi', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: OrderingInformationScreen(
            chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
              'idNumber': 'ZO254207410B',
              'sex': 'FEMALE',
            }),
            sdkOcr: OcrResult(
              nationality: 'id',
              permittedDate: '20250710',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Residency card number + gender dari chip
      expect(find.text('IC CHIP'), findsNWidgets(2));
      // Nationality + permission to land dari SDK OCR
      expect(find.text('SDK OCR'), findsNWidgets(2));
    });

    testWidgets('4 ikon kalender untuk 4 field tanggal', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_month), findsNWidgets(4));
    });

    testWidgets('tap ikon kalender membuka date picker', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_month).first);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarDatePicker), findsOneWidget);
    });

    testWidgets('dropdown Visa Status bisa dipilih', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(_wrap(withData: false, nationality: 'id'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose Visa Status'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PERMANENT RESIDENT').last);
      await tester.pumpAndSettle();

      expect(find.text('PERMANENT RESIDENT'), findsOneWidget);
    });

    testWidgets('tombol Selesai memunculkan error untuk field wajib kosong',
        (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(_wrap(withData: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsWidgets);
    });

    testWidgets('tombol Selesai dan Lihat Log tampil', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Lihat Log'), findsOneWidget);
    });
  });
}

/// Viewport tinggi biar seluruh field kebikin (ListView cuma build yang
/// kelihatan).
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget _wrap({
  bool withData = true,
  String? nationality,
  OcrResult? sdkOcrExtra,
  LiquidDocumentType? documentType = LiquidDocumentType.residenceCard,
}) {
  return MaterialApp(
    home: OrderingInformationScreen(
      documentType: documentType,
      sdkOcr: withData
          ? _ocr
          : (nationality == null && sdkOcrExtra == null
              ? null
              : OcrResult(
                  nationality: nationality,
                  address: sdkOcrExtra?.address,
                )),
    ),
  );
}

final OcrResult _ocr = OcrResult(
  idNumber: 'ZO254207410B',
  expireDate: '20300710',
  nationality: 'id',
  residentStatus: '永住者',
  permittedDate: '20250710',
  stayExpireDate: '20300710',
);
