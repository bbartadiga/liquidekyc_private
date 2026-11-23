import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/services/app_logger.dart';
import 'package:module_liquid/core/services/log_sanitizer.dart';
import 'package:module_liquid/data/models/ordering_information_draft.dart';
import 'package:module_liquid/persentation/viewmodels/ordering_information_viewmodel.dart';

void main() {
  group('Log halaman Ordering Information', () {
    test('nulis ringkasan sumber data per field', () {
      appLogger.clear();

      OrderingInformationViewModel(
        draft: OrderingInformationDraft(
          residenceCardNumber: 'ZO254207410B',
          expiredDate: DateTime(2030, 7, 10),
          nationality: 'Indonesian',
          visaStatus: 'Permanent Resident',
        ),
      );

      final messages = appLogger.logs.map((e) => e.message).join('\n');

      expect(messages, contains('filled=4/13'));
      expect(messages, contains('residenceCardNumber -> -'));
      expect(messages, contains('kosong=['));
    });

    test('nilai PII form nggak bocor ke log', () {
      appLogger.clear();

      OrderingInformationViewModel(
        draft: OrderingInformationDraft(
          residenceCardNumber: 'ZO254207410B',
          orderingCustomerNameEnglish: 'MINISTRY OF JUSTICE',
          address1: '千代田区',
          address2: '千代田1-1',
          postalCode: '1000001',
        ),
      );

      final messages = appLogger.logs.map((e) => e.message).join('\n');

      expect(messages, isNot(contains('ZO254207410B')));
      expect(messages, isNot(contains('MINISTRY OF JUSTICE')));
      expect(messages, isNot(contains('千代田区')));
      expect(messages, isNot(contains('1000001')));
    });

    test('perubahan manual dicatat tanpa nilai', () {
      appLogger.clear();

      final vm = OrderingInformationViewModel();
      vm.notifyFieldEdited(OrderingField.address1);

      final messages = appLogger.logs.map((e) => e.message).join('\n');
      expect(messages, contains('diubah manual'));
      expect(messages, contains('field=address1'));
    });
  });

  group('LogSanitizer', () {
    test('key field form ikut tersensor', () {
      const raw = 'expireDate=20300710 | gender=02: FEMALE | '
          'permissionToLand=20250710 | periodToStay=20300710 | sex=MALE';

      final sanitized = LogSanitizer.sanitize(raw);

      expect(sanitized, isNot(contains('20300710')));
      expect(sanitized, isNot(contains('FEMALE')));
      expect(sanitized, isNot(contains('20250710')));
      expect(sanitized, isNot(contains('MALE')));
    });
  });
}
