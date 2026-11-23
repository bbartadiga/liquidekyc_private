import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/constant/liquid_constants.dart';
import 'package:module_liquid/data/models/applicant_info_payload.dart';
import 'package:module_liquid/data/models/chip_data.dart';
import 'package:module_liquid/data/models/ocr_result.dart';
import 'package:module_liquid/data/services/be/be_call_runner.dart';

/// Payload 016 RegisterApplicationInfo — spec LIQUID_eKYC_016 v1.3.4.
void main() {
  group('ApplicantInfoPayload - field kartu tinggal (016 field 18-23)', () {
    test('dikirim dari OCR, format mentah kartu', () {
      final payload = ApplicantInfoPayload.fromKycData(
        applicantId: 'APP-1',
        chipData: null,
        ocrResult: OcrResult(
          name: '山田 太郎',
          birthday: '19980215',
          address: '東京都千代田区大手町1-6-1',
          addressPref: '東京都',
          addressCity: '千代田区',
          addressOther: '大手町 1-6-1',
          residentStatus: ' 永住者 PermanentResident',
          stayPeriod: '4 年 3 月',
          stayExpireDate: '20300709',
          permittedDate: '20250709',
          kindOfPermission: ' 在留資格変更許可 ( 東京山入国在留管理局長 )',
          employmentRestriction: ' 就労不可 ',
        ),
        selectedNationality: Nationality.japan,
      );

      final body = payload.toBody();
      expect(body['resident_status'], '永住者 PermanentResident');
      expect(body['stay_period'], '4 年 3 月');
      expect(body['stay_expire_date'], '20300709');
      expect(body['permitted_date'], '20250709');
      expect(body['kind_of_permission'], '在留資格変更許可 ( 東京山入国在留管理局長 )');
      expect(body['employment_restriction'], '就労不可');
    });

    test('Gen-2 pakai varian KODE dari chip', () {
      final payload = ApplicantInfoPayload.fromKycData(
        applicantId: 'APP-1',
        chipData: LiquidChipDataModel.fromMap(<String, dynamic>{
          'liquidDocumentType': 'RESIDENCE_DOCUMENT_GEN2',
          'name': '山田 太郎',
          'birthday': '19980215',
          'address': '東京都千代田区大手町1-6-1',
          'residenceDocumentGen2': <String, dynamic>{
            'residenceStatusCode': 'T18',
            'kindOfPermissionCode': 'D0',
            'stayPeriodYear': '05',
            'stayPeriodMonths': '03',
            'stayPeriodDay': '10',
            'stayExpireDate': '20300709',
            'permittedDate': '20250709',
          },
        }),
        // OCR Gen-2 balikin × untuk field residence (lihat 013 v1.9.0 hal.21).
        ocrResult: null,
        selectedNationality: Nationality.japan,
      );

      final body = payload.toBody();
      // Varian kode (Gen-2).
      expect(body['resident_status_code'], 'T18');
      expect(body['kind_of_permission_code'], 'D0');
      expect(body['stay_period_year'], '05');
      expect(body['stay_period_month'], '03');
      expect(body['stay_period_day'], '10');
      expect(body['stay_expire_date'], '20300709');
      expect(body['permitted_date'], '20250709');
      // Varian teks (RC Gen 1) nggak dikirim untuk Gen-2.
      expect(body.containsKey('resident_status'), isFalse);
      expect(body.containsKey('stay_period'), isFalse);
      expect(body.containsKey('kind_of_permission'), isFalse);
      expect(body.containsKey('employment_restriction'), isFalse);
    });

    test('dikosongin kalau OCR-nya nggak punya (kartu non-tinggal)', () {
      final payload = ApplicantInfoPayload.fromKycData(
        applicantId: 'APP-1',
        chipData: null,
        ocrResult: OcrResult(
          name: '山田 太郎',
          birthday: '19980215',
          address: '東京都千代田区大手町1-6-1',
        ),
        selectedNationality: Nationality.japan,
      );

      final body = payload.toBody();
      expect(body.containsKey('resident_status'), isFalse);
      expect(body.containsKey('stay_period'), isFalse);
      expect(body.containsKey('stay_expire_date'), isFalse);
      expect(body.containsKey('permitted_date'), isFalse);
      expect(body.containsKey('kind_of_permission'), isFalse);
      expect(body.containsKey('employment_restriction'), isFalse);
    });
  });

  group('ApplicantInfoPayload.toBody', () {
    test('field opsional null dibuang', () {
      final payload = ApplicantInfoPayload(
        applicantId: 'APP-1',
        firstName: 'Budi',
        birthday: '19900102',
        address1: 'Jl. Merdeka 1',
      );

      final body = payload.toBody();
      expect(body['applicant_id'], 'APP-1');
      expect(body['first_name'], 'Budi');
      expect(body['birthday'], '19900102');
      expect(body['address1'], 'Jl. Merdeka 1');
      expect(body.containsKey('middle_name'), isFalse);
      expect(body.containsKey('nationality'), isFalse);
      expect(body.containsKey('phone_number'), isFalse);
      expect(body.containsKey('address4'), isFalse);
    });

    test('semua field terpakai ikut terkirim', () {
      final payload = ApplicantInfoPayload(
        applicantId: 'APP-1',
        firstName: 'Budi',
        lastName: 'Santoso',
        middleName: 'Mid',
        firstNameKana: 'ブディ',
        lastNameKana: 'サントソ',
        middleNameKana: 'ミッド',
        birthday: '19900102',
        nationality: 'ID',
        sex: '1',
        zipCode: '1000001',
        phoneNumber: '08123456789',
        address1: 'Jl. Merdeka 1',
        address2: 'Jakarta',
        address3: 'Menteng',
        address4: 'No 5',
        idNumber: 'T12345678',
      );

      expect(payload.toBody().length, 17);
      expect(payload.toBody()['id_number'], 'T12345678');
    });
  });

  group('ApplicantInfoPayload.fromKycData', () {
    test('nama full-width My Number Card dipisah di spasi full-width', () {
      final chip = LiquidChipDataModel(
        name: 'ＤＨＩＫＡ　ＰＲＡＴＡＭＡ',
        birthday: '19931113',
        sex: Sex.male,
        addressPref: '東京都',
        addressCity: '新宿区',
        addressOther: '西新宿',
        address: '1-2-3',
        zipCode: '1600023',
      );

      final payload = ApplicantInfoPayload.fromKycData(
        applicantId: 'APP-1',
        chipData: chip,
        ocrResult: null,
        selectedNationality: Nationality.japan,
      );

      expect(payload.lastName, 'ＤＨＩＫＡ');
      expect(payload.firstName, 'ＰＲＡＴＡＭＡ');
      // nameKana null → field kana pakai nama yang ada
      expect(payload.lastNameKana, 'ＤＨＩＫＡ');
      expect(payload.firstNameKana, 'ＰＲＡＴＡＭＡ');
      expect(payload.birthday, '19931113');
      expect(payload.nationality, 'JP');
      expect(payload.sex, '1');
    });

    test('alamat dipisah jadi address1..4 sesuai spec', () {
      final chip = LiquidChipDataModel(
        name: '山田 太郎',
        nameKana: 'ヤマダ タロウ',
        birthday: '19900102',
        addressPref: '東京都',
        addressCity: '新宿区',
        addressOther: '西新宿',
        address: '1-2-3',
      );

      final payload = ApplicantInfoPayload.fromKycData(
        applicantId: 'APP-1',
        chipData: chip,
        ocrResult: null,
        selectedNationality: Nationality.japan,
      );

      expect(payload.address1, '東京都');
      expect(payload.address2, '新宿区');
      expect(payload.address3, '西新宿');
      expect(payload.lastName, '山田');
      expect(payload.firstName, '太郎');
      expect(payload.lastNameKana, 'ヤマダ');
    });

    test('alamat nggak dipisah → semuanya di address1', () {
      final chip = LiquidChipDataModel(
        name: 'Budi Santoso',
        birthday: '19900102',
        address: 'Jl. Merdeka 1',
      );

      final payload = ApplicantInfoPayload.fromKycData(
        applicantId: 'APP-1',
        chipData: chip,
        ocrResult: null,
        selectedNationality: Nationality.indonesia,
      );

      expect(payload.address1, 'Jl. Merdeka 1');
      expect(payload.address2, isNull);
      expect(payload.nationality, 'ID');
    });

    test('tanpa chip → fallback nama & tanggal tetap valid', () {
      final payload = ApplicantInfoPayload.fromKycData(
        applicantId: 'APP-1',
        chipData: null,
        ocrResult: null,
        selectedNationality: Nationality.indonesia,
      );

      expect(payload.firstName, 'User');
      expect(payload.birthday.length, 8);
      expect(payload.address1, isNotEmpty);
    });

    test('tanggal sebelum 1900 ditolak (spec: system error)', () {
      final chip = LiquidChipDataModel(name: 'A B', birthday: '18991231');

      final payload = ApplicantInfoPayload.fromKycData(
        applicantId: 'APP-1',
        chipData: chip,
        ocrResult: null,
        selectedNationality: Nationality.japan,
      );

      expect(payload.birthday, '19000101');
    });
  });

  group('BeCallRunner', () {
    test('ekstrak kode error dari body BE', () {
      const body =
          '{"error_code":"CE00019","error_message":"ocr is not available"}';
      expect(BeCallRunner.extractErrorCode(body), 'CE00019');
      expect(BeCallRunner.extractErrorCode('gagal biasa'), isNull);
    });

    test('kode transien dikenali', () {
      expect(
        BeCallRunner.isTransientMessage('{"error_code":"CE00017"}'),
        isTrue,
      );
      expect(
        BeCallRunner.isTransientMessage('{"error_code":"CE00008"}'),
        isTrue,
      );
      expect(
        BeCallRunner.isTransientMessage('{"error_code":"CE00019"}'),
        isFalse,
      );
    });

    test('retry jalan saat error transien, berhenti saat bukan', () async {
      final runner = BeCallRunner(
        spacing: Duration.zero,
        maxAttempts: 3,
      );
      var calls = 0;

      final result = await runner.runWithRetry<int>(
        () async {
          calls++;
          return calls; // 1 = transien, 2 = bukan
        },
        isTransient: (r) => r == 1,
      );

      expect(result, 2);
      expect(calls, 2);
    });

    test('retry berhenti di maxAttempts', () async {
      final runner = BeCallRunner(
        spacing: Duration.zero,
        maxAttempts: 3,
      );
      var calls = 0;

      await runner.runWithRetry<int>(
        () async {
          calls++;
          return 1;
        },
        isTransient: (_) => true,
      );

      expect(calls, 3);
    });
  });
}
