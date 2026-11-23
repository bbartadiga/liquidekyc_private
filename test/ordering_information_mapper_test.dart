import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/services/japanese_date_parser.dart';
import 'package:module_liquid/data/models/chip_data.dart';
import 'package:module_liquid/data/models/ocr_result.dart';
import 'package:module_liquid/data/models/ocr_results_response.dart';
import 'package:module_liquid/data/models/ordering_information_draft.dart';
import 'package:module_liquid/persentation/viewmodels/ordering_information_viewmodel.dart';

void main() {
  group('JapaneseDateParser', () {
    test('8 digit YYYYMMDD', () {
      expect(JapaneseDateParser.parse('20300710'), DateTime(2030, 7, 10));
    });

    test('format Japan YYYY年M月D日', () {
      expect(JapaneseDateParser.parse('2030年7月10日'), DateTime(2030, 7, 10));
      expect(JapaneseDateParser.parse('2025年12月01日'), DateTime(2025, 12, 1));
    });

    test('format terpisah YYYY-M-D dan YYYY / M / D', () {
      expect(JapaneseDateParser.parse('2030-07-10'), DateTime(2030, 7, 10));
      expect(JapaneseDateParser.parse('2030 / 7 / 10'), DateTime(2030, 7, 10));
    });

    test('format nggak dikenal atau null -> null', () {
      expect(JapaneseDateParser.parse(null), isNull);
      expect(JapaneseDateParser.parse(''), isNull);
      expect(JapaneseDateParser.parse('n/a'), isNull);
      expect(JapaneseDateParser.parse('20301350'), isNull);
    });
  });

  group('OrderingInformationMapper', () {
    test('data chip dipakai duluan daripada OCR', () {
      final chip = LiquidChipDataModel.fromMap(<String, dynamic>{
        'idNumber': 'CHIP123',
        'expireDate': '20300710',
      });

      final draft = OrderingInformationMapper.fromKycData(
        chipData: chip,
        sdkOcr: OcrResult(idNumber: 'OCR123', expireDate: '20200101'),
      );

      expect(draft.residenceCardNumber, 'CHIP123');
      expect(draft.expiredDate, DateTime(2030, 7, 10));
    });

    test('field lengkap dari OCR', () {
      final draft = OrderingInformationMapper.fromKycData(
        sdkOcr: OcrResult(
          idNumber: 'ZO254207410B',
          expireDate: '20300710',
          nationality: 'INDONESIA',
          residentStatus: '永住者',
          permittedDate: '20250710',
          stayExpireDate: '20300710',
        ),
      );

      expect(draft.residenceCardNumber, 'ZO254207410B');
      expect(draft.expiredDate, DateTime(2030, 7, 10));
      expect(draft.nationality, 'Indonesian');
      // Nilai status tinggal = kode BE (uppercase), sumber: caseVisaStatus()
      // di host app.
      expect(draft.visaStatus, 'PERMANENT RESIDENT');
      expect(draft.permissionToLandDate, DateTime(2025, 7, 10));
      expect(draft.periodToStayDate, DateTime(2030, 7, 10));
    });

    test('kode kebangsaan & status tinggal diterjemahkan', () {
      final draft = OrderingInformationMapper.fromKycData(
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'residenceDocumentGen2': <String, dynamic>{
            // Kode kebangsaan Gen-2 format alpha-3 (lihat
            // liquidNationalityNames3 di project).
            'nationalityCode': 'JPN',
          },
        }),
      );

      expect(draft.nationality, 'Japanese');
    });

    test('nilai mentah yang nggak dikenal tetap diteruskan apa adanya', () {
      final draft = OrderingInformationMapper.fromKycData(
        sdkOcr: OcrResult(
          nationality: 'VIETNAMESE',
          residentStatus: 'SHORT_TERM_RESIDENT',
        ),
      );

      expect(draft.nationality, 'Vietnamese');
      // Nggak ada di tabel BE → diteruskan apa adanya (default host app).
      expect(draft.visaStatus, 'SHORT_TERM_RESIDENT');
    });

    test('status tinggal dari kartu (bentuk Japan) dipetakan ke kode BE', () {
      // Data nyata di PPT "Result OCR NFC Digiremit": OCR SDK ngasih
      // resident_status "企業内転勤".
      final draft = OrderingInformationMapper.fromKycData(
        sdkOcr: OcrResult(residentStatus: '企業内転勤'),
      );

      expect(draft.visaStatus, 'INTRA-COMPANY TRANSFEREE');
    });

    test('data kosong -> draft kosong, bukan error', () {
      final draft = OrderingInformationMapper.fromKycData();

      expect(draft.residenceCardNumber, '');
      expect(draft.expiredDate, isNull);
      expect(draft.nationality, isNull);
      expect(draft.visaStatus, isNull);
      expect(draft.permissionToLandDate, isNull);
      expect(draft.periodToStayDate, isNull);
    });
  });

  group('OrderingInformationMapper - field lanjutan', () {
    test('nama ENGLISH dari kana chip jadi romaji huruf besar', () {
      final draft = OrderingInformationMapper.fromKycData(
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'name': '法務省',
          'nameKana': 'ほうむしょう',
        }),
      );

      expect(draft.orderingCustomerNameEnglish, startsWith('HOUMU'));
      expect(
        draft.orderingCustomerNameEnglish,
        draft.orderingCustomerNameEnglish.toUpperCase(),
      );
    });

    test('gender dari OCR format angka (1/2/3)', () {
      final male = OrderingInformationMapper.fromKycData(
        sdkOcr: OcrResult(sex: '1'),
      );
      final female = OrderingInformationMapper.fromKycData(
        sdkOcr: OcrResult(sex: '2'),
      );
      final others = OrderingInformationMapper.fromKycData(
        sdkOcr: OcrResult(sex: '3'),
      );

      expect(male.gender, '01: MALE');
      expect(female.gender, '02: FEMALE');
      expect(others.gender, '03: OTHERS');
    });

    test('gender dari chip format angka (1/2/3) atau nama', () {
      final byNumber = OrderingInformationMapper.fromKycData(
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'sex': '2',
        }),
      );
      final byName = OrderingInformationMapper.fromKycData(
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'sex': 'MALE',
        }),
      );

      expect(byNumber.gender, '02: FEMALE');
      expect(byName.gender, '01: MALE');
    });

    test('nama latin dari OCR dipakai langsung', () {
      final draft = OrderingInformationMapper.fromKycData(
        sdkOcr: OcrResult(name: 'Ministry of Justice'),
      );

      expect(draft.orderingCustomerNameEnglish, 'MINISTRY OF JUSTICE');
    });

    test('gender diformat 01/02/03', () {
      final draft = OrderingInformationMapper.fromKycData(
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'sex': 'FEMALE',
        }),
      );

      expect(draft.gender, '02: FEMALE');
    });

    test('tanggal lahir, kode pos, dan pemecahan alamat', () {
      final draft = OrderingInformationMapper.fromKycData(
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'birthday': '19980215',
          'zipCode': '1000001',
          'addressPref': '東京都',
          'addressCity': '千代田区',
          'addressOther': '千代田1-1',
          'address': '東京都千代田区千代田1-1 内閣府ビル 5階',
        }),
      );

      expect(draft.dateOfBirth, DateTime(1998, 2, 15));
      expect(draft.postalCode, '1000001');
      // Address 1 = pref + city, Address 2 = other, Address 3 = opsional
      expect(draft.address1, '東京都千代田区');
      expect(draft.address2, '千代田1-1');
      expect(draft.address3, '');
    });

    test('alamat yang nggak dipecah masuk ke Address 1', () {
      // My Number / Driving License cuma punya satu string address penuh.
      final draft = OrderingInformationMapper.fromKycData(
        sdkOcr: OcrResult(
          address: '東京都品川区上大崎2−10−11 アビティ目黒401',
        ),
      );

      expect(draft.address1, '東京都品川区上大崎2−10−11 アビティ目黒401');
      expect(draft.address2, '');
      expect(draft.address3, '');
    });

    test('nama per karakter (kartu My Number) dirapikan', () {
      final draft = OrderingInformationMapper.fromKycData(
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'name': 'D H I K A  P R A T A M A',
        }),
      );

      expect(draft.orderingCustomerNameEnglish, 'DHIKA PRATAMA');
    });

    test('nama full-width jadi half-width', () {
      final draft = OrderingInformationMapper.fromKycData(
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'name': 'ＤＨＩＫＡ　ＰＲＡＴＡＭＡ',
        }),
      );

      expect(draft.orderingCustomerNameEnglish, 'DHIKA PRATAMA');
    });

    test('nama latin lebih diprioritaskan daripada kana', () {
      final draft = OrderingInformationMapper.fromKycData(
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'name': 'ＤＨＩＫＡ　ＰＲＡＴＡＭＡ',
          'nameKana': 'デイカ　プラターマ',
        }),
      );

      expect(draft.orderingCustomerNameEnglish, 'DHIKA PRATAMA');
    });

    test('nama kanji disimpan buat konversi async (jp_transliterate)', () {
      final draft = OrderingInformationMapper.fromKycData(
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'name': '山田太郎',
          'nameKana': 'ヤマダ タロウ',
        }),
      );

      // Nilai sync dari kana, kanjinya disimpan buat jalur async.
      expect(draft.orderingCustomerNameRaw, '山田太郎');
      expect(draft.orderingCustomerNameEnglish, 'YAMADA TAROU');
    });

    test('status tinggal dari bentuk berkategori (kartu) dipetakan', () {
      final draft = OrderingInformationMapper.fromKycData(
        sdkOcr: OcrResult(residentStatus: '技術・人文知識・国際業務'),
      );

      expect(
        draft.visaStatus,
        'ENGINEER/SPECIALIST IN HUMANITIES/INTERNATIONAL SERVICES',
      );
    });
  });

  group('OrderingInformationViewModel - nama', () {
    test('setOrderingCustomerName menormalkan hasil romaji', () {
      final vm = OrderingInformationViewModel();

      vm.setOrderingCustomerName('Yamada Tarō');

      expect(vm.orderingCustomerNameEnglishController.text, 'YAMADA TARŌ');
    });
  });

  group('OrderingInformationMapper - multi source per field', () {
    test('field fallback ke sumber berikutnya kalau sumber pertama kosong', () {
      final draft = OrderingInformationMapper.fromKycData(
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'idNumber': 'CHIP123',
          'expireDate': '20300710',
        }),
        sdkOcr: OcrResult(
          idNumber: 'OCR123',
          permittedDate: '20250710',
        ),
        beOcr: OcrResultsBeResponse(
          isSuccess: true,
          zipCode: '1000001',
        ),
      );

      // Chip wins untuk field yang dia punya
      expect(draft.residenceCardNumber, 'CHIP123');
      expect(
        draft.sourceOf(OrderingField.residenceCardNumber),
        OrderingFieldSource.chip,
      );
      expect(
        draft.sourceOf(OrderingField.expiredDate),
        OrderingFieldSource.chip,
      );

      // Chip nggak punya "Permission to Land" → turun ke SDK OCR
      expect(draft.permissionToLandDate, DateTime(2025, 7, 10));
      expect(
        draft.sourceOf(OrderingField.permissionToLandDate),
        OrderingFieldSource.sdkOcr,
      );

      // Zip code cuma ada di BE OCR
      expect(draft.postalCode, '1000001');
      expect(
        draft.sourceOf(OrderingField.postalCode),
        OrderingFieldSource.beOcr,
      );
    });

    test('field yang nggak ada di sumber mana pun ditandai manual', () {
      final draft = OrderingInformationMapper.fromKycData();

      expect(draft.sourceOf(OrderingField.postalCode),
          OrderingFieldSource.manual);
      expect(draft.sourceOf(OrderingField.address1),
          OrderingFieldSource.manual);
      expect(
        draft.sourceOf(OrderingField.orderingCustomerNameEnglish),
        OrderingFieldSource.manual,
      );
    });

    test('nama & gender dari sumber berbeda tetap kepakai', () {
      final draft = OrderingInformationMapper.fromKycData(
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'nameKana': 'ほうむしょう',
          'sex': 'MALE',
        }),
        beOcr: OcrResultsBeResponse(
          isSuccess: true,
          name: 'Ministry of Justice',
          nationality: 'ID',
          residentStatus: 'PERMANENT_RESIDENT',
        ),
      );

      // Nama latin (BE OCR) lebih baik daripada kana dari chip → dipilih.
      expect(draft.orderingCustomerNameEnglish, 'MINISTRY OF JUSTICE');
      expect(
        draft.sourceOf(OrderingField.orderingCustomerNameEnglish),
        OrderingFieldSource.beOcr,
      );
      expect(draft.gender, '01: MALE');
      expect(draft.sourceOf(OrderingField.gender), OrderingFieldSource.chip);

      // BE OCR nationality pakai alpha-2
      expect(draft.nationality, 'Indonesian');
      expect(
        draft.sourceOf(OrderingField.nationality),
        OrderingFieldSource.beOcr,
      );
    });
  });
}
