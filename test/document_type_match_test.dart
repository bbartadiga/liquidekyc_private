import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/constant/liquid_document_type.dart';
import 'package:module_liquid/data/models/chip_data.dart';
import 'package:module_liquid/data/models/chip_verification.dart';
import 'package:module_liquid/persentation/viewmodels/kyc_viewmodel.dart';

/// Cek kecocokan tipe dokumen WAJIB pakai hasil chip dari run yang sedang jalan.
///
/// Callback-nya dipanggil sebelum `KycViewModel` meng-assign hasil chip, jadi
/// kalau implementation-nya baca field yang sudah ada, dia bandingin sama
/// data run SEBELUMNYA → false mismatch.
void main() {
  group('Cek kecocokan tipe dokumen', () {
    test('pakai chip run ini, bukan run sebelumnya', () {
      // Chip yang sekarang dibaca = Residence Card, padahal yang diminta
      // Driver's License → tidak cocok.
      expect(
        KycViewModel.isDocumentTypeMismatchFor(
          LiquidDocumentType.driverLicense,
          _chip(LiquidDocumentType.residenceCard),
        ),
        isTrue,
      );

      // Chip yang sekarang dibaca = Driver's License → cocok.
      expect(
        KycViewModel.isDocumentTypeMismatchFor(
          LiquidDocumentType.driverLicense,
          _chip(LiquidDocumentType.driverLicense),
        ),
        isFalse,
      );
    });

    test('chip yang tidak melaporkan tipe dokumen → dianggap tidak mismatch',
        () {
      expect(
        KycViewModel.isDocumentTypeMismatchFor(
          LiquidDocumentType.residenceCard,
          ChipVerificationResult(
            status: ChipVerificationResultStatus.success,
          ),
        ),
        isFalse,
      );
    });

    test('Residence Card Gen-2 kompatibel dengan kartu biasa', () {
      expect(
        KycViewModel.isDocumentTypeMismatchFor(
          LiquidDocumentType.residenceDocumentGen2,
          _chip(LiquidDocumentType.residenceCard),
        ),
        isFalse,
      );
    });
  });
}

ChipVerificationResult _chip(LiquidDocumentType type) {
  return ChipVerificationResult(
    status: ChipVerificationResultStatus.success,
    chipData: LiquidChipDataModel(
      liquidDocumentType: type.value,
    ),
  );
}
