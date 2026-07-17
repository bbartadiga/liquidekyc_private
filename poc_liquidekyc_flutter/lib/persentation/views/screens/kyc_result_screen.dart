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

        // Source Toggle
        _buildSourceToggle(),

        const SizedBox(height: 8),

        // Show data based on toggle
        if (_showSdkData) ...[
          // SDK Data Section
          _buildSectionHeader('SDK - Real-time Data', Icons.code, Colors.blue),
          const SizedBox(height: 8),
          
          // OCR Data (SDK - Quick Preview) - SELALU TAMPIL
          _buildOcrSdkSection(),

          // IC Chip Section (SDK) - SELALU TAMPIL
          _buildChipSection(isSdk: true),

          // Face Verification Section (SDK) - SELALU TAMPIL
          _buildFaceSection(isSdk: true),

          // Document Section (SDK) - SELALU TAMPIL
          _buildDocumentSection(),
        ] else ...[
          // BE Data Section
          _buildSectionHeader('BE - Official Data', Icons.cloud_done, Colors.green),
          const SizedBox(height: 8),

          // OCR Data (BE - Official) - SELALU TAMPIL
          _buildOcrBeSection(),

          // IC Chip Section (BE) - SELALU TAMPIL
          _buildChipSection(isSdk: false),

          // Face Verification Section (BE) - SELALU TAMPIL
          _buildFaceSection(isSdk: false),

          // Photos Section (BE) - SELALU TAMPIL
          _buildPhotosSection(),

          // Liveness Images Section (BE) - SELALU TAMPIL
          _buildLivenessSection(),
        ],

        const SizedBox(height: 16),

        // BE API Status Section
        _buildBeApiStatusSection(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary() {
    final docStatus = _deriveDocumentStatus();
    final chipStatus = widget.chipResult?.isSuccess == true || widget.beICCardInfo?.isSuccess == true;
    final faceStatus = widget.faceResult?.isSuccess == true || widget.beVerificationResults?.isSuccess == true;
    
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
            status: docStatus,
          ),
          _buildStatusItem(
            icon: Icons.nfc,
            label: 'IC Chip',
            status: chipStatus,
          ),
          _buildStatusItem(
            icon: Icons.face,
            label: 'Face',
            status: faceStatus,
          ),
        ],
      ),
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

  Widget _buildOcrSdkSection() {
    return _buildSection(
      title: 'Data Kartu (OCR - SDK Preview)',
      icon: Icons.article,
      color: Colors.blue,
      children: [
        _buildDetailPlaceholder('Nama', widget.ocrName),
        _buildDetailPlaceholder('Alamat', widget.ocrAddress, maxLines: 2),
        _buildDetailPlaceholder('Tanggal Lahir', widget.ocrDateOfBirth),
        _buildDetailPlaceholder('No. Dokumen', widget.ocrDocumentNumber),
        _buildDetailPlaceholder('Nasionalitas', widget.ocrNationality),
        _buildDetailPlaceholder('Residence Status', widget.ocrResidenceStatus),
        const Divider(height: 8),
        _buildSourceTag('SDK - Preview (Fast)'),
      ],
    );
  }

  Widget _buildOcrBeSection() {
    final ocr = widget.beOcrResults;
    return _buildSection(
      title: 'Data Kartu (BE Official)',
      icon: Icons.verified_user,
      color: Colors.green,
      children: [
        _buildDetailPlaceholder('Nama', ocr?.name),
        _buildDetailPlaceholder('Jenis Kelamin', ocr?.sex != null ? _formatSex(ocr!.sex!) : null),
        _buildDetailPlaceholder('Tanggal Lahir', ocr?.birthday),
        _buildDetailPlaceholder('No. Dokumen', ocr?.idNumber),
        _buildDetailPlaceholder('Alamat', ocr?.address, maxLines: 2),
        _buildDetailPlaceholder('Alamat Lengkap', ocr?.fullAddress, maxLines: 2),
        _buildDetailPlaceholder('Zip Code', ocr?.zipCode),
        _buildDetailPlaceholder('Nasionalitas', ocr?.nationality),
        _buildDetailPlaceholder('Tgl Kadaluarsa', ocr?.expireDate != null ? _formatDate(ocr!.expireDate!) : null),
        _buildDetailPlaceholder('Tgl Terbit', ocr?.issueDate != null ? _formatDate(ocr!.issueDate!) : null),
        _buildDetailPlaceholder('Residence Status', ocr?.residentStatus),
        _buildDetailPlaceholder('Stay Period', ocr?.stayPeriod),
        _buildDetailPlaceholder('Stay Expire', ocr?.stayExpireDate != null ? _formatDate(ocr!.stayExpireDate!) : null),
        const Divider(height: 8),
        _buildSourceTag('BE - Official (Validated)'),
      ],
    );
  }

  String _formatDate(String date) {
    if (date.length == 8) {
      return '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)}';
    }
    return date;
  }

  String _formatSex(String sex) {
    switch (sex) {
      case '1':
        return 'Laki-laki';
      case '2':
        return 'Perempuan';
      default:
        return sex;
    }
  }

  Widget _buildBeApiStatusSection() {
    // Count successful API calls
    int successCount = 0;
    final apis = [
      widget.isRegisterApplicationInfoSuccess ?? false,
      widget.beVerificationResults?.isSuccess ?? false,
      widget.beOcrResults?.isSuccess ?? false,
      widget.beICCardInfo?.isSuccess ?? false,
      widget.beLivenessImages?.isSuccess ?? false,
      widget.bePhotos?.isSuccess ?? false,
    ];
    for (final api in apis) {
      if (api) successCount++;
    }

    // Dynamic color based on success ratio
    final Color sectionColor;
    if (successCount == 6) {
      sectionColor = Colors.green;
    } else if (successCount >= 3) {
      sectionColor = Colors.orange;
    } else {
      sectionColor = Colors.red;
    }

    return _buildSection(
      title: 'BE API Status ($successCount/6)',
      icon: Icons.cloud_done,
      color: sectionColor,
      children: [
        _buildApiStatusRow('Register App Info', widget.isRegisterApplicationInfoSuccess ?? false),
        _buildApiStatusRow('Verification Results', widget.beVerificationResults?.isSuccess ?? false),
        _buildApiStatusRow('OCR Results (BE)', widget.beOcrResults?.isSuccess ?? false),
        _buildApiStatusRow('IC Card Info', widget.beICCardInfo?.isSuccess ?? false),
        _buildApiStatusRow('Liveness Images', widget.beLivenessImages?.isSuccess ?? false,
            count: widget.beLivenessImages?.livenessImages?.length),
        _buildApiStatusRow('Document Photos', widget.bePhotos?.isSuccess ?? false,
            count: widget.bePhotos?.idDocumentPhotos?.length),
      ],
    );
  }

  Widget _buildApiStatusRow(String label, bool success, {int? count}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            size: 16,
            color: success ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count photos',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildChipSection({required bool isSdk}) {
    if (isSdk) {
      final sdkChipData = widget.chipResult?.chipData;
      return _buildSection(
        title: 'Verifikasi IC Chip',
        icon: Icons.nfc,
        color: Colors.purple,
        children: [
          _buildDetailPlaceholder('Status', widget.chipResult?.isSuccess == true ? 'Berhasil' : 'Gagal'),
          _buildDetailPlaceholder('Auto Verify', widget.chipResult?.autoVerificationResult?.result.name),
          _buildSourceTag('SDK'),
          const Divider(height: 16),
          _buildDetailPlaceholder('Nama', sdkChipData?.displayName),
          _buildDetailPlaceholder('Nama Kana', sdkChipData?.nameKana),
          _buildDetailPlaceholder('Alamat', sdkChipData?.fullAddress, maxLines: 2),
          _buildDetailPlaceholder('Tgl Lahir', sdkChipData?.displayBirthday),
          _buildDetailPlaceholder('Jenis Kelamin', sdkChipData?.displaySex),
          _buildDetailPlaceholder('No. Dokumen', sdkChipData?.displayIdNumber),
          _buildDetailPlaceholder('Tgl Kadaluarsa', sdkChipData?.displayExpireDate),
        ],
      );
    } else {
      final beChipData = widget.beICCardInfo;
      return _buildSection(
        title: 'Verifikasi IC Chip',
        icon: Icons.nfc,
        color: Colors.green.shade700,
        children: [
          _buildDetailPlaceholder('Status', beChipData?.isSuccess == true ? 'Berhasil' : 'Gagal'),
          _buildSourceTag('BE'),
          const Divider(height: 16),
          _buildDetailPlaceholder('Nama', beChipData?.displayName),
          _buildDetailPlaceholder('Nama Kana', beChipData?.nameKana),
          _buildDetailPlaceholder('Tgl Lahir', beChipData?.displayBirthday),
          _buildDetailPlaceholder('Jenis Kelamin', beChipData?.displaySex),
          _buildDetailPlaceholder('No. Dokumen', beChipData?.displayIdNumber),
          _buildDetailPlaceholder('Alamat', beChipData?.address, maxLines: 2),
          _buildDetailPlaceholder('Alamat Lengkap', beChipData?.fullAddress, maxLines: 2),
          _buildDetailPlaceholder('Tgl Kadaluarsa', beChipData?.displayExpireDate),
          _buildDetailPlaceholder('Tgl Terbit', beChipData?.displayIssueDate),
          _buildDetailPlaceholder('My Number', beChipData?.myNumber),
        ],
      );
    }
  }

  Widget _buildPhotosSection() {
    final photos = widget.bePhotos;
    final docPhotos = photos?.idDocumentPhotos ?? [];
    return _buildSection(
      title: 'Foto Dokumen',
      icon: Icons.photo_library,
      color: Colors.teal,
      children: [
        _buildSourceTag('BE'),
        const SizedBox(height: 8),
        _buildDetailPlaceholder('Foto Wajah', photos?.faceFrontPhoto != null ? 'Tersedia' : null),
        _buildDetailPlaceholder('Total Foto', '${docPhotos.length} foto'),
        const Divider(height: 8),
        if (docPhotos.isNotEmpty) ...[
          ...docPhotos.asMap().entries.map((entry) {
            final idx = entry.key;
            final photo = entry.value;
            return _buildDetailPlaceholder(
              'Foto ${idx + 1}',
              photo.fileName != null 
                  ? '${photo.fileName}${photo.isMasked == true ? ' (Masked)' : ''}' 
                  : null,
            );
          }),
        ] else ...[
          _buildDetailPlaceholder('Foto 1', null),
          _buildDetailPlaceholder('Foto 2', null),
          _buildDetailPlaceholder('Foto 3', null),
        ],
      ],
    );
  }

  Widget _buildLivenessSection() {
    final images = widget.beLivenessImages?.livenessImages ?? [];
    return _buildSection(
      title: 'Foto Liveness',
      icon: Icons.face,
      color: Colors.orange,
      children: [
        _buildSourceTag('BE'),
        const SizedBox(height: 8),
        _buildDetailPlaceholder('Total Foto', '${images.length} foto'),
        const Divider(height: 8),
        if (images.isNotEmpty) ...[
          ...images.asMap().entries.map((entry) {
            final idx = entry.key;
            final image = entry.value;
            return _buildDetailPlaceholder('Foto ${idx + 1}', image.fileName);
          }),
        ] else ...[
          _buildDetailPlaceholder('Foto 1', null),
          _buildDetailPlaceholder('Foto 2', null),
          _buildDetailPlaceholder('Foto 3', null),
        ],
      ],
    );
  }

  Widget _buildFaceSection({required bool isSdk}) {
    if (isSdk) {
      return _buildSection(
        title: 'Verifikasi Wajah',
        icon: Icons.face,
        color: Colors.orange,
        children: [
          _buildDetailPlaceholder('Status', widget.faceResult?.isSuccess == true ? 'Berhasil' : 'Gagal'),
          _buildSourceTag('SDK'),
          const Divider(height: 8),
          _buildDetailPlaceholder('Info', 'Face verification dari SDK'),
        ],
      );
    } else {
      final verResults = widget.beVerificationResults;
      return _buildSection(
        title: 'Verifikasi Wajah',
        icon: Icons.face,
        color: Colors.green.shade700,
        children: [
          _buildDetailPlaceholder('Status', verResults?.isSuccess == true ? 'Berhasil' : 'Gagal'),
          _buildSourceTag('BE'),
          const Divider(height: 8),
          _buildDetailPlaceholder('Face Match', verResults?.faceMatchScore != null 
              ? '${verResults!.faceMatchScore!.toStringAsFixed(2)}%' 
              : null),
          _buildDetailPlaceholder('Liveness', verResults?.livenessResult),
          _buildDetailPlaceholder('Auto Verify', verResults?.autoVerificationStatus),
        ],
      );
    }
  }

  Widget _buildDocumentSection() {
    final docResult = widget.documentResult;
    return _buildSection(
      title: 'Verifikasi Dokumen',
      icon: Icons.badge,
      color: Colors.teal,
      children: [
        _buildDetailPlaceholder('Status', docResult?.isSuccess == true ? 'Berhasil' : 'Gagal'),
        _buildDetailPlaceholder('Info', docResult?.additionalDataTitle),
        _buildDetailPlaceholder('Auto Verify', docResult?.autoVerificationResult?.result.name),
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

  // Helper yang selalu tampil, kasih placeholder kalau null
  Widget _buildDetailPlaceholder(String label, String? value, {int maxLines = 1, String placeholder = '(data dari API)'}) {
    final displayValue = (value != null && value.isNotEmpty) ? value : placeholder;
    final isEmpty = value == null || value.isEmpty;
    
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
              displayValue,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isEmpty ? Colors.grey.shade400 : Colors.black87,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onDone,
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
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/debug'),
            icon: const Icon(Icons.bug_report, size: 18),
            label: const Text('Lihat Log'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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

  const KycSuccessScreen({
    super.key,
    this.result,
    required this.onDone,
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
      beVerificationResults: beVerificationResults,
      beOcrResults: beOcrResults,
      bePhotos: bePhotos,
      beLivenessImages: beLivenessImages,
      isRegisterApplicationInfoSuccess: isRegisterApplicationInfoSuccess,
      ocrName: ocrName,
      ocrAddress: ocrAddress,
      ocrDateOfBirth: ocrDateOfBirth,
      ocrDocumentNumber: ocrDocumentNumber,
      ocrNationality: ocrNationality,
      ocrResidenceStatus: ocrResidenceStatus,
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