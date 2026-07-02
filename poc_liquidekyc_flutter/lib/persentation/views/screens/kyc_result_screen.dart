import 'package:flutter/material.dart';
import '../../../data/models/kyc_result.dart';
import '../../../data/models/document_result.dart';
import '../../../data/models/face_results.dart';
import '../../../data/models/chip_result.dart';
import '../../../data/services/kyc_be_api.dart';
import '../../../core/services/app_logger.dart';

export '../../../data/models/chip_result.dart';
export '../../../data/models/face_results.dart';
export '../../../data/models/document_result.dart';

class KycResultScreen extends StatelessWidget {
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
  final String? ocrName;
  final String? ocrAddress;
  final String? ocrDateOfBirth;
  final String? ocrDocumentNumber;

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
    this.ocrName,
    this.ocrAddress,
    this.ocrDateOfBirth,
    this.ocrDocumentNumber,
  });

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
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildMessage(),
              if (errorCode != null) ...[
                const SizedBox(height: 12),
                _buildErrorCode(),
              ],
              if (isSuccess) ...[
                const SizedBox(height: 24),
                _buildVerificationResults(),
              ],
              const SizedBox(height: 32),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSuccess ? Icons.check_circle : Icons.error,
        size: 60,
        color: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          title ?? (isSuccess ? 'Verifikasi Berhasil' : 'Verifikasi Gagal'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        if (isSuccess) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'eKYC Complete',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessage() {
    String defaultMessage = isSuccess
        ? 'Identitas Anda telah berhasil diverifikasi.'
        : 'Terjadi kesalahan dalam proses verifikasi.';

    return Text(
      message ?? defaultMessage,
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
              errorCode ?? 'Unknown error',
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
        _buildStatusSummary(),
        
        const SizedBox(height: 16),
        
        // OCR Data
        if (ocrName != null || ocrAddress != null || ocrDateOfBirth != null)
          _buildOcrSection(),
        
        // IC Chip Section
        if (chipResult != null)
          _buildChipSection(),
        
        // Face Verification Section
        if (faceResult != null)
          _buildFaceSection(),
        
        // Document Section
        if (documentResult != null)
          _buildDocumentSection(),
      ],
    );
  }

  Widget _buildStatusSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusItem(
            icon: Icons.article,
            label: 'Document',
            status: _deriveDocumentStatus(),
          ),
          _buildStatusItem(
            icon: Icons.nfc,
            label: 'IC Chip',
            status: chipResult?.isSuccess ?? false,
          ),
          _buildStatusItem(
            icon: Icons.face,
            label: 'Face',
            status: faceResult?.isSuccess ?? false,
          ),
        ],
      ),
    );
  }

  bool? _deriveDocumentStatus() {
    // If documentResult exists (for non-COMPLY_HE methods), use it
    if (documentResult != null) {
      appLogger.d('[KYCRESULT] _deriveDocumentStatus: using documentResult.isSuccess=${documentResult!.isSuccess}');
      return documentResult!.isSuccess;
    }

    // For COMPLY_HE - document status derived from IC Chip auto verification
    // Card back photo is processed as part of verifyIdChip()
    if (chipResult != null) {
      appLogger.d('[KYCRESULT] _deriveDocumentStatus: using chipResult.autoVerificationResult');
      // autoVerificationResult indicates if card (including back side) passed
      final autoVerify = chipResult!.autoVerificationResult;
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
      if (chipResult!.isSuccess) {
        appLogger.d('[KYCRESULT] no autoVerify, but chipResult.isSuccess=true, returning true');
        return true;
      }
    }

    // Fallback: no data available
    appLogger.d('[KYCRESULT] _deriveDocumentStatus: returning null (no data)');
    return null;
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    bool? status,  // null = N/A (not executed)
  }) {
    final bool? displayStatus = status;
    final Color bgColor;
    final IconData iconData;
    final Color iconColor;

    if (displayStatus == null) {
      bgColor = Colors.grey.shade100;
      iconData = Icons.remove;
      iconColor = Colors.grey;
    } else if (displayStatus) {
      bgColor = Colors.green.shade100;
      iconData = Icons.check;
      iconColor = Colors.green;
    } else {
      bgColor = Colors.red.shade100;
      iconData = Icons.close;
      iconColor = Colors.red;
    }

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildOcrSection() {
    return _buildSection(
      title: 'Data Kartu (OCR)',
      icon: Icons.article,
      color: Colors.blue,
      children: [
        if (ocrName != null) _buildDetailRow('Nama', ocrName!),
        if (ocrAddress != null) _buildDetailRow('Alamat', ocrAddress!, maxLines: 2),
        if (ocrDateOfBirth != null) _buildDetailRow('Tanggal Lahir', ocrDateOfBirth!),
        if (ocrDocumentNumber != null) _buildDetailRow('No. Dokumen', ocrDocumentNumber!),
      ],
    );
  }

  Widget _buildChipSection() {
    final sdkChipData = chipResult?.chipData;
    final beChipData = beICCardInfo;
    final hasChipData = sdkChipData != null || (beChipData?.isSuccess == true);
    
    String chipSource = '✗ NULL';
    if (sdkChipData != null) {
      chipSource = '✓ SDK';
    } else if (beChipData?.isSuccess == true) {
      chipSource = '✓ BE';
    }
    
    return _buildSection(
      title: 'Verifikasi IC Chip',
      icon: Icons.nfc,
      color: Colors.purple,
      children: [
        _buildDetailRow('Status', chipResult!.isSuccess ? 'Berhasil' : 'Gagal'),
        if (chipResult!.autoVerificationResult != null)
          _buildDetailRow('Auto Verify', chipResult!.autoVerificationResult!.result.name),
        _buildDetailRow('🔍 ChipData', chipSource),
        const Divider(height: 16),
        if (sdkChipData != null) ...[
          _buildDetailRow('Nama', sdkChipData.displayName),
          if (sdkChipData.nameKana != null && sdkChipData.nameKana!.isNotEmpty)
            _buildDetailRow('Nama Kana', sdkChipData.nameKana!),
          _buildDetailRow('Alamat', sdkChipData.fullAddress),
          _buildDetailRow('Tgl Lahir', sdkChipData.displayBirthday),
          _buildDetailRow('Jenis Kelamin', sdkChipData.displaySex),
          _buildDetailRow('No. Dokumen', sdkChipData.displayIdNumber),
          _buildDetailRow('Tgl Kadaluarsa', sdkChipData.displayExpireDate),
        ] else if (beChipData?.isSuccess == true) ...[
          _buildDetailRow('Nama', beChipData!.displayName),
          if (beChipData.nameKana != null && beChipData.nameKana!.isNotEmpty)
            _buildDetailRow('Nama Kana', beChipData.nameKana!),
          _buildDetailRow('Alamat', beChipData.fullAddress),
          _buildDetailRow('Tgl Lahir', beChipData.displayBirthday),
          _buildDetailRow('Jenis Kelamin', beChipData.displaySex),
          _buildDetailRow('No. Dokumen', beChipData.displayIdNumber),
          _buildDetailRow('Tgl Kadaluarsa', beChipData.displayExpireDate),
        ] else ...[
          _buildDetailRow('Info', 'Data chip tidak tersedia'),
        ],
      ],
    );
  }

  Widget _buildFaceSection() {
    return _buildSection(
      title: 'Verifikasi Wajah',
      icon: Icons.face,
      color: Colors.orange,
      children: [
        _buildDetailRow('Status', faceResult!.isSuccess ? 'Berhasil' : 'Gagal'),
      ],
    );
  }

  Widget _buildDocumentSection() {
    return _buildSection(
      title: 'Verifikasi Dokumen',
      icon: Icons.badge,
      color: Colors.teal,
      children: [
        _buildDetailRow('Status', documentResult!.isSuccess ? 'Berhasil' : 'Gagal'),
        if (documentResult!.additionalDataTitle != null)
          _buildDetailRow('Info', documentResult!.additionalDataTitle!),
        if (documentResult!.autoVerificationResult != null)
          _buildDetailRow('Auto Verify', documentResult!.autoVerificationResult!.result.name),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        if (onNext != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
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
        if (!isSuccess && onRetry != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
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
        if (!isSuccess && onCancel != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCancel,
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
        if (onDone != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

// Simple wrapper screens
class KycSuccessScreen extends StatelessWidget {
  final KycResult? result;
  final VoidCallback onDone;
  final DocumentResult? documentResult;
  final FaceResult? faceResult;
  final ChipVerificationResult? chipResult;
  final ICCardInfoResponse? beICCardInfo;
  final String? ocrName;
  final String? ocrAddress;
  final String? ocrDateOfBirth;
  final String? ocrDocumentNumber;

  const KycSuccessScreen({
    super.key,
    this.result,
    required this.onDone,
    this.documentResult,
    this.faceResult,
    this.chipResult,
    this.beICCardInfo,
    this.ocrName,
    this.ocrAddress,
    this.ocrDateOfBirth,
    this.ocrDocumentNumber,
  });

  @override
  Widget build(BuildContext context) {
    return KycResultScreen(
      isSuccess: true,
      title: 'Verifikasi Berhasil!',
      message: 'Identitas Anda telah berhasil diverifikasi.',
      result: result,
      onDone: onDone,
      documentResult: documentResult,
      faceResult: faceResult,
      chipResult: chipResult,
      beICCardInfo: beICCardInfo,
      ocrName: ocrName,
      ocrAddress: ocrAddress,
      ocrDateOfBirth: ocrDateOfBirth,
      ocrDocumentNumber: ocrDocumentNumber,
    );
  }
}

class KycErrorScreen extends StatelessWidget {
  final String? title;
  final String? message;
  final String? errorCode;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const KycErrorScreen({
    super.key,
    this.title,
    this.message,
    this.errorCode,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return KycResultScreen(
      isSuccess: false,
      title: title ?? 'Verifikasi Gagal',
      message: message ?? 'Terjadi kesalahan dalam proses verifikasi. Silakan coba lagi.',
      errorCode: errorCode,
      onRetry: onRetry,
      onCancel: onCancel,
    );
  }
}