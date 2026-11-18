import '../../core/constant/liquid_constants.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/chip_attempt_guard.dart';
import '../models/chip_result.dart';
import '../models/document_result.dart';
import '../models/face_results.dart';
import '../repositories/kyc_repository.dart';

/// Hasil satu putaran verifikasi (IC chip → document → face).
class KycVerificationOutcome {
  final ChipVerificationResult? chipResult;
  final DocumentResult? documentResult;
  final FaceResult? faceResult;
  final OcrResult? ocrResult;
  final bool isSuccess;
  final String? errorCode;
  final String? errorMessage;

  /// Error ini bisa bikin kartu fisik terkunci (chip My Number Card punya
  /// contador percobaan). Kalau true, UI harus tampilkan dialog — bukan
  /// snackbar yang keburu hilang — supaya user nggak asal retry.
  final bool cardLockRisk;

  const KycVerificationOutcome({
    this.chipResult,
    this.documentResult,
    this.faceResult,
    this.ocrResult,
    this.isSuccess = true,
    this.errorCode,
    this.errorMessage,
    this.cardLockRisk = false,
  });

  const KycVerificationOutcome.failure(
    String code,
    String message, {
    this.chipResult,
    this.documentResult,
    this.faceResult,
    this.ocrResult,
    this.cardLockRisk = false,
  })  : isSuccess = false,
        errorCode = code,
        errorMessage = message;
}

/// Menjalankan rangkaian verifikasi sesuai urutan dari [VerificationMethod.verificationOrder].
class KycVerificationRunner {
  final KycRepository _repository;

  KycVerificationRunner({KycRepository? repository})
      : _repository = repository ?? KycRepository();

  Future<KycVerificationOutcome> run({
    required VerificationMethod method,
    required LiquidDocumentType documentType,
    required FaceVerificationType faceType,
    OcrResult? currentOcrResult,
    void Function(KycStep step)? onStep,
    void Function()? onChipVerified,
  }) async {
    final order = method.verificationOrder;
    var stepNum = 11;

    ChipVerificationResult? chipResult;
    DocumentResult? documentResult;
    FaceResult? faceResult;
    var ocrResult = currentOcrResult;

    for (final step in order) {
      if (step == 'icCard') {
        // Pengaman: jangan baca chip kalau percobaan sebelumnya sudah habis.
        // Counter ada di IC chip kartu, jadi restart app nggak bisa reset.
        if (!ChipAttemptGuard.canAttempt) {
          appLogger.e(
            '[STEP $stepNum] IC Card (NFC) → DIBLOKIR | '
            'gagal sebelumnya=${ChipAttemptGuard.failedAttempts}',
          );
          return KycVerificationOutcome.failure(
            'CHIP_ATTEMPTS_EXHAUSTED',
            ChipAttemptGuard.blockedMessage,
          );
        }

        appLogger.i('[STEP $stepNum] IC Card (NFC) → STARTING...');
        onStep?.call(KycStep.icCardRead);

        chipResult = await _repository.verifyIdChip(
          documentType: documentType,
          verificationMethod: method,
        );

        if (!chipResult.isSuccess) {
          final message = chipResult.userFriendlyMessage;
          final lockRisk = chipResult.liquidError.canLockCard;

          // Cuma error yang bisa mengunci kartu yang memotong counter.
          if (lockRisk) {
            await ChipAttemptGuard.recordFailure(chipResult.errorCode ?? 'UNKNOWN');
            appLogger.e(
              '[STEP $stepNum] Chip attempt recorded | '
              'gagal=${ChipAttemptGuard.failedAttempts}/${ChipAttemptGuard.maxAttempts} '
              'sisa=${ChipAttemptGuard.attemptsLeft}',
            );
          }

          appLogger.e('[STEP $stepNum] IC Card (NFC) → FAILED | code:${chipResult.errorCode} | msg:$message');
          return KycVerificationOutcome.failure('CHIP_ERROR', message,
              chipResult: chipResult, cardLockRisk: lockRisk);
        }
        appLogger.i('[STEP $stepNum] IC Card (NFC) → SUCCESS');
        await ChipAttemptGuard.reset();
        onChipVerified?.call();

        // Preview data kartu langsung setelah IC chip — biar UI cepat terisi
        if (ocrResult == null) {
          appLogger.i('[SDK] Calling getOcrResults() for quick preview...');
          ocrResult = await _repository.getOcrResults();
          if (ocrResult.name != null) {
            appLogger.i('[SDK] getOcrResults → SUCCESS | name:${ocrResult.name}');
          } else {
            appLogger.w('[SDK] getOcrResults → null or empty');
          }
        }
      }

      if (step == 'document') {
        appLogger.i('[STEP $stepNum] Document Scan (OCR) → STARTING...');
        onStep?.call(KycStep.documentScan);

        documentResult = await _repository.verifyDocument(
          documentType: documentType,
          verificationMethod: method,
        );

        if (!documentResult.isSuccess) {
          final message = documentResult.userFriendlyMessage;
          appLogger.e('[STEP $stepNum] Document Scan (OCR) → FAILED | code:${documentResult.errorCode} | msg:$message');
          return KycVerificationOutcome.failure('DOCUMENT_ERROR', message,
              documentResult: documentResult, ocrResult: ocrResult);
        }
        appLogger.i('[STEP $stepNum] Document Scan (OCR) → SUCCESS');

        ocrResult = await _repository.getOcrResults();
        appLogger.i('[STEP $stepNum] OCR data extracted → name:${ocrResult.name ?? "N/A"}');
      }

      if (step == 'face') {
        appLogger.i('[STEP $stepNum] Face Verify → STARTING...');
        onStep?.call(KycStep.faceScan);

        faceResult = await _repository.verifyFace(
          faceVerificationType: faceType,
        );

        if (!faceResult.isSuccess) {
          final message = faceResult.userFriendlyMessage;
          appLogger.e('[STEP $stepNum] Face Verify → FAILED | code:${faceResult.errorCode} | msg:$message');
          return KycVerificationOutcome.failure('FACE_ERROR', message,
              chipResult: chipResult,
              documentResult: documentResult,
              faceResult: faceResult,
              ocrResult: ocrResult);
        }
        appLogger.i('[STEP $stepNum] Face Verify → SUCCESS | autoVerify:${faceResult.autoVerificationResult?.result.name ?? "N/A"}');
      }

      stepNum++;
    }

    return KycVerificationOutcome(
      chipResult: chipResult,
      documentResult: documentResult,
      faceResult: faceResult,
      ocrResult: ocrResult,
    );
  }
}
