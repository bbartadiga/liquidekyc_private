import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/data/models/chip_result.dart';

/// Parser data chip dari native (VerificationHandler.buildChipDataMap) ke Dart.
///
/// Semua getter non-Bitmap di LiquidChipData SDK 1.47.0 harus diteruskan —
/// kalau ada yang kelewat, datanya hilang permanen di sisi app.
void main() {
  group('Sex', () {
    test('OTHERS diparse, bukan unknown', () {
      expect(Sex.fromString('OTHERS'), Sex.others);
      expect(Sex.fromString('MALE'), Sex.male);
      expect(Sex.fromString('FEMALE'), Sex.female);
      expect(Sex.fromString('n/a'), Sex.unknown);
    });

    test('sex dari int (1/2) tetap jalan', () {
      final model = LiquidChipDataModel.fromMap({'sex': 1});
      expect(model.sex, Sex.male);

      final model2 = LiquidChipDataModel.fromMap({'sex': 2});
      expect(model2.sex, Sex.female);
    });
  });

  group('LiquidChipDataModel - field inti', () {
    final map = <String, dynamic>{
      'name': '山田 太郎',
      'nameKana': 'ヤマダ タロウ',
      'nameHalfWidthKana': 'ヤマダ タロウ',
      'birthday': '19900102',
      'sex': 'MALE',
      'address': '1-2-3',
      'addressPref': '東京都',
      'addressCity': '新宿区',
      'addressOther': '西新宿1-2-3',
      'zipCode': '1600023',
      'idNumber': 'T12345678',
      'issueDate': '20200101',
      'expireDate': '20300101',
      'myNumber': '1234567890123',
      'liquidDocumentType': 'RESIDENCE_CARD',
      'residenceCardType': '1',
      'residenceCardTypeEnum': 'RESIDENCE_CARD',
      'residenceCardInfoType': 'PERMANENT',
      'hasIdFacePhoto': true,
      'hasDocumentFrontImage': true,
      'hasAddressImage': true,
    };

    test('field dasar ke-parse', () {
      final model = LiquidChipDataModel.fromMap(map);
      expect(model.name, '山田 太郎');
      expect(model.nameKana, 'ヤマダ タロウ');
      expect(model.birthday, '19900102');
      expect(model.sex, Sex.male);
      expect(model.zipCode, '1600023');
      expect(model.myNumber, '1234567890123');
      expect(model.hasAddressImage, isTrue);
    });

    test('displayMyNumber disensor 4 digit terakhir', () {
      final model = LiquidChipDataModel.fromMap(map);
      expect(model.displayMyNumber, '*******0123');
    });

    test('fullAddress menggabungkan pref + city + other', () {
      final model = LiquidChipDataModel.fromMap(map);
      expect(model.fullAddress, '東京都 新宿区 西新宿1-2-3 1-2-3');
    });
  });

  group('LiquidChipDataModel - field baru', () {
    test('nama: kandidat kana, nama sebelumnya, alias', () {
      final model = LiquidChipDataModel.fromMap({
        'nameHalfWidthKana': 'ﾔﾏﾀﾞ ﾀﾛｳ',
        'lastNameKanaCandidates': ['ヤマダ', 'やまだ'],
        'lastNameHalfWidthKanaCandidates': ['ﾔﾏﾀﾞ'],
        'firstNameKanaCandidates': ['タロウ', 'たろう'],
        'firstNameHalfWidthKanaCandidates': ['ﾀﾛｳ'],
        'previousName': '佐藤 花子',
        'previousLastNameKanaCandidates': ['サトウ'],
        'previousLastNameHalfWidthKanaCandidates': ['ｻﾄｳ'],
        'aliasName': '太郎',
      });

      expect(model.nameHalfWidthKana, 'ﾔﾏﾀﾞ ﾀﾛｳ');
      expect(model.lastNameKanaCandidates, ['ヤマダ', 'やまだ']);
      expect(model.lastNameHalfWidthKanaCandidates, ['ﾔﾏﾀﾞ']);
      expect(model.firstNameKanaCandidates, ['タロウ', 'たろう']);
      expect(model.firstNameHalfWidthKanaCandidates, ['ﾀﾛｳ']);
      expect(model.previousName, '佐藤 花子');
      expect(model.previousLastNameKanaCandidates, ['サトウ']);
      expect(model.previousLastNameHalfWidthKanaCandidates, ['ｻﾄｳ']);
      expect(model.aliasName, '太郎');
    });

    test('alamat: riwayat perubahan alamat', () {
      final model = LiquidChipDataModel.fromMap({
        'addressModificationHistories': ['-old-1-2-3', '-old-4-5-6'],
      });

      expect(model.addressModificationHistories, ['-old-1-2-3', '-old-4-5-6']);
    });

    test('status tinggal: movedAbroad, psc, foreigner judgment', () {
      final model = LiquidChipDataModel.fromMap({
        'movedAbroad': 'NO',
        'plannedAbroadMoveDate': '20270101',
        'japaneseForeignerJudgment': 'JAPANESE',
        'pscName': '旧住所',
        'pscNames': ['旧住所1', '旧住所2'],
      });

      expect(model.movedAbroad, 'NO');
      expect(model.plannedAbroadMoveDate, '20270101');
      expect(model.japaneseForeignerJudgment, 'JAPANESE');
      expect(model.pscName, '旧住所');
      expect(model.pscNames, ['旧住所1', '旧住所2']);
    });
  });

  group('ResidenceDocumentGen2', () {
    final gen2Map = <String, dynamic>{
      'comprehensivePermissionCode': 'CP-001',
      'expireDateOfComprehensivePermission': '20300101',
      'individualPermission': 'EXIST',
      'residenceDocumentGen2InfoType': 'GENERAL',
      'nationalityCode': 'JPN',
      'residenceStatusCode': 'RS-01',
      'stayPeriodYear': '5',
      'stayPeriodMonths': '3',
      'stayPeriodDay': '10',
      'kindOfPermissionCode': 'KP-01',
      'permittedDate': '20250101',
      'employmentRestriction': 'NONE',
      'stayExpireDate': '20300101',
      'stayUpdateStatus': 'NONE',
      'immigrationCommissionerStatement': 'RECORDED',
    };

    test('semua field Gen-2 ke-parse', () {
      final model = LiquidChipDataModel.fromMap({
        'residenceDocumentGen2': gen2Map,
      });

      final gen2 = model.residenceDocumentGen2;
      expect(gen2, isNotNull);
      expect(gen2!.comprehensivePermissionCode, 'CP-001');
      expect(gen2.expireDateOfComprehensivePermission, '20300101');
      expect(gen2.individualPermission, 'EXIST');
      expect(gen2.residenceDocumentGen2InfoType, 'GENERAL');
      expect(gen2.nationalityCode, 'JPN');
      expect(gen2.residenceStatusCode, 'RS-01');
      expect(gen2.stayPeriodYear, '5');
      expect(gen2.kindOfPermissionCode, 'KP-01');
      expect(gen2.permittedDate, '20250101');
      expect(gen2.employmentRestriction, 'NONE');
      expect(gen2.stayExpireDate, '20300101');
      expect(gen2.stayUpdateStatus, 'NONE');
      expect(gen2.immigrationCommissionerStatement, 'RECORDED');
      expect(gen2.isEmpty, isFalse);
    });

    test('masa tinggal digabung Y / M / D', () {
      final model = LiquidChipDataModel.fromMap({
        'residenceDocumentGen2': gen2Map,
      });
      expect(model.residenceDocumentGen2!.stayPeriod, '5 / 3 / 10');
    });

    test('izin individual fallback ke field level atas buat kartu non Gen-2', () {
      final model = LiquidChipDataModel.fromMap({
        'residenceCardIndividualPermission': 'EXIST',
        'residenceCardComprehensivePermission': 'CP-LEGACY',
      });

      expect(model.displayIndividualPermission, 'EXIST');
      expect(model.displayComprehensivePermission, 'CP-LEGACY');
      expect(model.isResidenceDocumentGen2, isFalse);
    });

    test('Gen-2: izin individual dibaca dari residenceDocumentGen2', () {
      final model = LiquidChipDataModel.fromMap({
        'residenceCardIndividualPermission': null,
        'residenceDocumentGen2': gen2Map,
      });

      expect(model.displayIndividualPermission, 'EXIST');
      expect(model.displayComprehensivePermission, 'CP-001');
      expect(model.displayGen2InfoType, 'GENERAL');
      expect(model.isResidenceDocumentGen2, isTrue);
    });
  });

  group('MyNumberCardIntegratedDriverLicense', () {
    test('data SIM terintegrasi ke-parse', () {
      final model = LiquidChipDataModel.fromMap({
        'myNumberCardIntegratedDriverLicense': {
          'colorCategory': 'BLUE',
          'conditions': ['condition-1'],
          'types': ['type-1', 'type-2'],
          'remarks': ['remark-1'],
          'acquisitionDates': ['20200101'],
          'recordNumber': 'REC-123',
          'validUntil': '20300101',
        },
      });

      final dl = model.myNumberCardIntegratedDriverLicense;
      expect(dl, isNotNull);
      expect(dl!.colorCategory, 'BLUE');
      expect(dl.conditions, ['condition-1']);
      expect(dl.types, ['type-1', 'type-2']);
      expect(dl.remarks, ['remark-1']);
      expect(dl.acquisitionDates, ['20200101']);
      expect(dl.recordNumber, 'REC-123');
      expect(dl.validUntil, '20300101');
      expect(dl.isEmpty, isFalse);
    });

    test('tidak ada data → objek kosong, bukan null crash', () {
      final model = LiquidChipDataModel.fromMap({});
      expect(model.myNumberCardIntegratedDriverLicense, isNotNull);
      expect(model.myNumberCardIntegratedDriverLicense!.isEmpty, isTrue);
    });
  });
}
