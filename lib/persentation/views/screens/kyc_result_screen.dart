import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/app_logger.dart';
import '../../../data/models/chip_result.dart';
import '../../../data/models/document_result.dart';
import '../../../data/models/face_results.dart';
import '../../../data/models/ic_card_info_response.dart';
import '../../../data/models/kyc_result.dart';
import '../../../data/models/liveness_images_response.dart';
import '../../../data/models/ocr_results_response.dart';
import '../../../data/models/photos_response.dart';
import '../../../data/models/verification_results_response.dart';
import '../../viewmodels/kyc_viewmodel.dart';
import '../widgets/app_action_buttons.dart';
import '../widgets/kyc_result_identity_sections.dart';
import '../widgets/kyc_result_verification_sections.dart';
import '../widgets/kyc_result_widgets.dart';

export '../../../data/models/chip_result.dart';
export '../../../data/models/face_results.dart';
export '../../../data/models/document_result.dart';

class KycResultScreen extends StatefulWidget {
  final bool isSuccess;
  final String? title;
  final String? message;
  final String? errorCode;
  final KycResult? result;
  final VoidCallback? onRetry;
  final VoidCallback? onDone;
  final VoidCallback? onNext;
  final VoidCallback? onCancel;
  
  // Additional data from verification
  final DocumentResult? documentResult;
  final FaceResult? faceResult;
  final ChipVerificationResult? chipResult;
  final ICCardInfoResponse? beICCardInfo;
  final VerificationResultsResponse? beVerificationResults;
  final OcrResultsBeResponse? beOcrResults;
  final PhotosResponse? bePhotos;
  final LivenessImagesResponse? beLivenessImages;
  final bool? isRegisterApplicationInfoSuccess;
  final String? ocrName;
  final String? ocrAddress;
  final String? ocrDateOfBirth;
  final String? ocrDocumentNumber;
  final String? ocrNationality;
  final String? ocrResidenceStatus;
  final int? pendingQueueCount;

  const KycResultScreen({
    super.key,
    required this.isSuccess,
    this.title,
    this.message,
    this.errorCode,
    this.result,
    this.onRetry,
    this.onDone,
    this.onNext,
    this.onCancel,
    this.documentResult,
    this.faceResult,
    this.chipResult,
    this.beICCardInfo,
    this.beVerificationResults,
    this.beOcrResults,
    this.bePhotos,
    this.beLivenessImages,
    this.isRegisterApplicationInfoSuccess,
    this.ocrName,
    this.ocrAddress,
    this.ocrDateOfBirth,
    this.ocrDocumentNumber,
    this.ocrNationality,
    this.ocrResidenceStatus,
    this.pendingQueueCount,
  });

  bool get hasQueuedRequests => (pendingQueueCount ?? 0) > 0;
  int get pendingQueueCountValue => pendingQueueCount ?? 0;

  @override
  State<KycResultScreen> createState() => _KycResultScreenState();
}

class _KycResultScreenState extends State<KycResultScreen> {
  bool _showSdkData = true;

  bool get _isOverallSuccess {
    final documentOk = _deriveDocumentStatus() == true;
    final chipOk = widget.chipResult?.isSuccess == true || widget.beICCardInfo?.isSuccess == true;
    final faceOk = widget.faceResult?.isSuccess == true || widget.beVerificationResults?.isSuccess == true;
    return widget.isSuccess && (documentOk || chipOk) && faceOk;
  }

  bool get _isPartialSuccess {
    final hasChipData = widget.chipResult?.isSuccess == true || widget.beICCardInfo?.isSuccess == true;
    final hasFaceData = widget.faceResult?.isSuccess == true || widget.beVerificationResults?.isSuccess == true;
    return hasChipData || hasFaceData;
  }

  Color get _statusColor {
    if (_isOverallSuccess) return Colors.green;
    if (_isPartialSuccess) return Colors.orange;
    return Colors.red;
  }

  Color get _statusBgColor {
    if (_isOverallSuccess) return Colors.green.shade50;
    if (_isPartialSuccess) return Colors.orange.shade50;
    return Colors.red.shade50;
  }

  String get _statusTitle {
    if (_isOverallSuccess) return 'Verifikasi Berhasil';
    if (_isPartialSuccess) return 'Verifikasi Sebagian';
    return 'Verifikasi Gagal';
  }

  String get _statusBadge {
    if (_isOverallSuccess) return 'eKYC Complete';
    if (_isPartialSuccess) return 'Partial';
    return 'Failed';
  }

  String get _statusMessage {
    if (_isOverallSuccess) return 'Identitas Anda telah berhasil diverifikasi.';
    if (_isPartialSuccess) return 'Beberapa langkah berhasil. Mohon coba lagi.';
    return 'Terjadi kesalahan dalam proses verifikasi.';
  }

  int get _successCount {
    int count = 0;
    if (_deriveDocumentStatus() == true) count++;
    if (widget.chipResult?.isSuccess == true || widget.beICCardInfo?.isSuccess == true) count++;
    if (widget.faceResult?.isSuccess == true || widget.beVerificationResults?.isSuccess == true) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildIcon(),
              if (widget.hasQueuedRequests) ...[
                const SizedBox(height: 16),
                _buildQueueIndicator(),
              ],
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildMessage(),
              if (widget.errorCode != null) ...[
                const SizedBox(height: 12),
                _buildErrorCode(),
              ],
              // SELALU tampilkan detail verifikasi, apapun statusnya
              const SizedBox(height: 24),
              _buildVerificationResults(),
              const SizedBox(height: 32),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showSdkData = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showSdkData ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.code,
                      size: 18,
                      color: _showSdkData ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SDK Data',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _showSdkData ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showSdkData = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showSdkData ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud,
                      size: 18,
                      color: !_showSdkData ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BE Data',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: !_showSdkData ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync,
            size: 20,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${widget.pendingQueueCountValue} request sedang di-queue dan akan di-retry secara otomatis',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    final IconData icon;
    if (_isOverallSuccess) {
      icon = Icons.check_circle;
    } else if (_isPartialSuccess) {
      icon = Icons.warning;
    } else {
      icon = Icons.error;
    }
    
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: _statusBgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 60,
        color: _statusColor,
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          widget.title ?? _statusTitle,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _statusColor,
          ),
          textAlign: TextAlign.center,
        ),
        if (_isOverallSuccess) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _statusBadge,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        if (_isPartialSuccess && !_isOverallSuccess) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_successCount/3 Steps Completed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessage() {
    return Text(
      widget.message ?? _statusMessage,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorCode() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.errorCode ?? 'Unknown error',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationResults() {
    final viewModel = context.read<KycViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Verifikasi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // Status Summary
        KycStatusSummary(
          documentStatus: _deriveDocumentStatus(),
          chipOk: widget.chipResult?.isSuccess == true ||
              widget.beICCardInfo?.isSuccess == true,
          faceOk: widget.faceResult?.isSuccess == true ||
              widget.beVerificationResults?.isSuccess == true,
        ),

        const SizedBox(height: 16),

        // Identitas Dokumen (auto-detected from BE)
        KycIdentityCard(
          showSdkData: _showSdkData,
          beOcrResults: widget.beOcrResults,
          sdkOcr: viewModel.ocrResult,
          chipData: viewModel.chipVerificationResult?.chipData,
          selectedNationality: viewModel.selectedNationality,
          selectedDocumentType: viewModel.selectedDocumentType,
          actualDocumentType: viewModel.actualDocumentType,
          hasMismatch: viewModel.isDocumentTypeMismatch,
        ),

        const SizedBox(height: 16),

        // Source Toggle
        _buildSourceToggle(),

        const SizedBox(height: 8),

        // Show data based on toggle
        if (_showSdkData) ...[
          // SDK Data Section
          buildSectionHeader('SDK - Real-time Data', Icons.code, Colors.blue),
          const SizedBox(height: 8),
          
          // OCR Data (SDK - Quick Preview) - SELALU TAMPIL
          KycOcrSdkSection(
            sdkOcr: viewModel.ocrResult,
            chipData: viewModel.chipVerificationResult?.chipData,
            ocrName: widget.ocrName,
            ocrAddress: widget.ocrAddress,
            ocrDateOfBirth: widget.ocrDateOfBirth,
            ocrDocumentNumber: widget.ocrDocumentNumber,
            ocrNationality: widget.ocrNationality,
            ocrResidenceStatus: widget.ocrResidenceStatus,
          ),

          // IC Chip Section (SDK) - SELALU TAMPIL
          KycChipSection(isSdk: true, chipResult: widget.chipResult),

          // Face Verification Section (SDK) - SELALU TAMPIL
          KycFaceSection(isSdk: true, faceResult: widget.faceResult),

          // Document Section (SDK) - SELALU TAMPIL
          KycDocumentSection(documentResult: widget.documentResult),
        ] else ...[
          // BE Data Section
          buildSectionHeader('BE - Official Data', Icons.cloud_done, Colors.green),
          const SizedBox(height: 8),

          // OCR Data (BE - Official) - SELALU TAMPIL
          KycOcrBeSection(ocr: widget.beOcrResults, ic: widget.beICCardInfo),

          // Gen-2 / Specified Residence Card section (auto-show kalau cardType terdeteksi)
          KycGen2CardSection(ocr: widget.beOcrResults, ic: widget.beICCardInfo),

          // IC Chip Section (BE) - SELALU TAMPIL
          KycChipSection(isSdk: false, beICCardInfo: widget.beICCardInfo),

          // Face Verification Section (BE) - SELALU TAMPIL
          KycFaceSection(
              isSdk: false, beVerificationResults: widget.beVerificationResults),

          // Photos Section (BE) - SELALU TAMPIL
          KycPhotosSection(bePhotos: widget.bePhotos),

          // Liveness Images Section (BE) - SELALU TAMPIL
          KycLivenessSection(beLivenessImages: widget.beLivenessImages),
        ],

        const SizedBox(height: 16),

        // BE API Status Section
        KycBeApiStatusSection(
          isRegisterApplicationInfoSuccess: widget.isRegisterApplicationInfoSuccess,
          beVerificationResults: widget.beVerificationResults,
          beOcrResults: widget.beOcrResults,
          beICCardInfo: widget.beICCardInfo,
          beLivenessImages: widget.beLivenessImages,
          bePhotos: widget.bePhotos,
        ),
      ],
    );
  }

  bool? _deriveDocumentStatus() {
    // If documentResult exists (for non-COMPLY_HE methods), use it
    if (widget.documentResult != null) {
      appLogger.d('[KYCRESULT] _deriveDocumentStatus: using documentResult.isSuccess=${widget.documentResult!.isSuccess}');
      return widget.documentResult!.isSuccess;
    }

    // For COMPLY_HE - document status derived from IC Chip auto verification
    // Card back photo is processed as part of verifyIdChip()
    if (widget.chipResult != null) {
      appLogger.d('[KYCRESULT] _deriveDocumentStatus: using chipResult.autoVerificationResult');
      // autoVerificationResult indicates if card (including back side) passed
      final autoVerify = widget.chipResult!.autoVerificationResult;
      if (autoVerify != null) {
        appLogger.d('[KYCRESULT] autoVerify.result=${autoVerify.result.name}, message=${autoVerify.message}');
        // PASS = success, FAIL = fail, NOT_APPLICABLE = green check (no check needed)
        switch (autoVerify.result) {
          case AutoVerificationResultStatus.pass:
            return true;
          case AutoVerificationResultStatus.fail:
            return false;
          case AutoVerificationResultStatus.notApplicable:
            return true;  // No verification needed, show green
          case AutoVerificationResultStatus.unknown:
            return null;  // Unknown, show N/A
        }
      }
      // If IC Chip is successful but no auto verification result, consider it pass
      if (widget.chipResult!.isSuccess) {
        appLogger.d('[KYCRESULT] no autoVerify, but chipResult.isSuccess=true, returning true');
        return true;
      }
    }

    // Fallback: no data available
    appLogger.d('[KYCRESULT] _deriveDocumentStatus: returning null (no data)');
    return null;
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        if (widget.onNext != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lanjutkan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (!widget.isSuccess && widget.onRetry != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        if (!widget.isSuccess && widget.onCancel != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (widget.onDone != null)
          AppFinishButton(onPressed: widget.onDone),
        const SizedBox(height: 16),
        const AppLogButton(),
      ],
    );
  }
}
