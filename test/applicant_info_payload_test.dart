import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/constant/liquid_constants.dart';
import 'package:module_liquid/data/models/applicant_info_payload.dart';
import 'package:module_liquid/data/models/chip_data.dart';
import 'package:module_liquid/data/services/be/be_call_runner.dart';

/// Payload 016 RegisterApplicationInfo — spec LIQUID_eKYC_016 v1.3.4.
void main() {
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
