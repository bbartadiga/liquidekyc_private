import 'package:flutter/material.dart';

import '../../../data/models/chip_result.dart';
import '../../../data/models/document_result.dart';
import '../../../data/models/face_results.dart';
import '../../../data/models/ic_card_info_response.dart';
import '../../../data/models/liveness_images_response.dart';
import '../../../data/models/ocr_results_response.dart';
import '../../../data/models/photos_response.dart';
import '../../../data/models/verification_results_response.dart';
import 'kyc_result_widgets.dart';

class KycChipSection extends StatelessWidget {
  final bool isSdk;
  final ChipVerificationResult? chipResult;
  final ICCardInfoResponse? beICCardInfo;

  const KycChipSection({
    super.key,
    required this.isSdk,
    this.chipResult,
    this.beICCardInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (isSdk) {
      final sdkChipData = chipResult?.chipData;
      return buildSection(
        title: 'Verifikasi IC Chip',
        icon: Icons.nfc,
        color: Colors.purple,
        children: [
          buildDetailPlaceholder(
              'Status', chipResult?.isSuccess == true ? 'Berhasil' : 'Gagal'),
          buildDetailPlaceholder(
              'Auto Verify', chipResult?.autoVerificationResult?.result.name),
          buildSourceTag('SDK'),
          const Divider(height: 16),
          buildDetailPlaceholder('Nama', sdkChipData?.displayName),
          buildDetailPlaceholder('Nama Kana', sdkChipData?.nameKana),
          buildDetailPlaceholder('Alamat', sdkChipData?.fullAddress, maxLines: 2),
          buildDetailPlaceholder('Tgl Lahir', sdkChipData?.displayBirthday),
          buildDetailPlaceholder('Jenis Kelamin', sdkChipData?.displaySex),
          buildDetailPlaceholder('No. Dokumen', sdkChipData?.displayIdNumber),
          buildDetailPlaceholder('Tgl Kadaluarsa', sdkChipData?.displayExpireDate),
        ],
      );
    }

    final beChipData = beICCardInfo;
    return buildSection(
      title: 'Verifikasi IC Chip',
      icon: Icons.nfc,
      color: Colors.green.shade700,
      children: [
        buildDetailPlaceholder(
            'Status', beChipData?.isSuccess == true ? 'Berhasil' : 'Gagal'),
        buildSourceTag('BE'),
        const Divider(height: 16),
        buildDetailPlaceholder('Nama', beChipData?.displayName),
        buildDetailPlaceholder('Nama Kana', beChipData?.nameKana),
        buildDetailPlaceholder('Tgl Lahir', beChipData?.displayBirthday),
        buildDetailPlaceholder('Jenis Kelamin', beChipData?.displaySex),
        buildDetailPlaceholder('No. Dokumen', beChipData?.displayIdNumber),
        buildDetailPlaceholder('Alamat', beChipData?.address, maxLines: 2),
        buildDetailPlaceholder('Alamat Lengkap', beChipData?.fullAddress, maxLines: 2),
        buildDetailPlaceholder('Tgl Kadaluarsa', beChipData?.displayExpireDate),
        buildDetailPlaceholder('Tgl Terbit', beChipData?.displayIssueDate),
        buildDetailPlaceholder('My Number', beChipData?.myNumber),
      ],
    );
  }
}

/// Hasil verifikasi wajah (SDK atau BE)
class KycFaceSection extends StatelessWidget {
  final bool isSdk;
  final FaceResult? faceResult;
  final VerificationResultsResponse? beVerificationResults;

  const KycFaceSection({
    super.key,
    required this.isSdk,
    this.faceResult,
    this.beVerificationResults,
  });

  @override
  Widget build(BuildContext context) {
    if (isSdk) {
      return buildSection(
        title: 'Verifikasi Wajah',
        icon: Icons.face,
        color: Colors.orange,
        children: [
          buildDetailPlaceholder(
              'Status', faceResult?.isSuccess == true ? 'Berhasil' : 'Gagal'),
          buildSourceTag('SDK'),
          const Divider(height: 8),
          buildDetailPlaceholder('Info', 'Face verification dari SDK'),
        ],
      );
    }

    final verResults = beVerificationResults;
    return buildSection(
      title: 'Verifikasi Wajah',
      icon: Icons.face,
      color: Colors.green.shade700,
      children: [
        buildDetailPlaceholder(
            'Status', verResults?.isSuccess == true ? 'Berhasil' : 'Gagal'),
        buildSourceTag('BE'),
        const Divider(height: 8),
        buildDetailPlaceholder(
            'Face Match',
            verResults?.faceMatchScore != null
                ? '${verResults!.faceMatchScore!.toStringAsFixed(2)}%'
                : null),
        buildDetailPlaceholder('Liveness', verResults?.livenessResult),
        buildDetailPlaceholder('Auto Verify', verResults?.autoVerificationStatus),
      ],
    );
  }
}

/// Hasil verifikasi dokumen (hanya non-COMPLY_HE)
class KycDocumentSection extends StatelessWidget {
  final DocumentResult? documentResult;

  const KycDocumentSection({super.key, this.documentResult});

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'Verifikasi Dokumen',
      icon: Icons.badge,
      color: Colors.teal,
      children: [
        buildDetailPlaceholder(
            'Status', documentResult?.isSuccess == true ? 'Berhasil' : 'Gagal'),
        buildDetailPlaceholder('Info', documentResult?.additionalDataTitle),
        buildDetailPlaceholder(
            'Auto Verify', documentResult?.autoVerificationResult?.result.name),
      ],
    );
  }
}

/// Daftar foto dokumen dari BE
class KycPhotosSection extends StatelessWidget {
  final PhotosResponse? bePhotos;

  const KycPhotosSection({super.key, this.bePhotos});

  @override
  Widget build(BuildContext context) {
    final docPhotos = bePhotos?.idDocumentPhotos ?? [];
    return buildSection(
      title: 'Foto Dokumen',
      icon: Icons.photo_library,
      color: Colors.teal,
      children: [
        buildSourceTag('BE'),
        const SizedBox(height: 8),
        buildDetailPlaceholder(
            'Foto Wajah', bePhotos?.faceFrontPhoto != null ? 'Tersedia' : null),
        buildDetailPlaceholder('Total Foto', '${docPhotos.length} foto'),
        const Divider(height: 8),
        if (docPhotos.isNotEmpty) ...[
          ...docPhotos.asMap().entries.map((entry) {
            final idx = entry.key;
            final photo = entry.value;
            return buildDetailPlaceholder(
              'Foto ${idx + 1}',
              photo.fileName != null
                  ? '${photo.fileName}${photo.isMasked == true ? ' (Masked)' : ''}'
                  : null,
            );
          }),
        ] else ...[
          buildDetailPlaceholder('Foto 1', null),
          buildDetailPlaceholder('Foto 2', null),
          buildDetailPlaceholder('Foto 3', null),
        ],
      ],
    );
  }
}

/// Daftar foto liveness dari BE
class KycLivenessSection extends StatelessWidget {
  final LivenessImagesResponse? beLivenessImages;

  const KycLivenessSection({super.key, this.beLivenessImages});

  @override
  Widget build(BuildContext context) {
    final images = beLivenessImages?.livenessImages ?? [];
    return buildSection(
      title: 'Foto Liveness',
      icon: Icons.face,
      color: Colors.orange,
      children: [
        buildSourceTag('BE'),
        const SizedBox(height: 8),
        buildDetailPlaceholder('Total Foto', '${images.length} foto'),
        const Divider(height: 8),
        if (images.isNotEmpty) ...[
          ...images.asMap().entries.map((entry) {
            final idx = entry.key;
            final image = entry.value;
            return buildDetailPlaceholder('Foto ${idx + 1}', image.fileName);
          }),
        ] else ...[
          buildDetailPlaceholder('Foto 1', null),
          buildDetailPlaceholder('Foto 2', null),
          buildDetailPlaceholder('Foto 3', null),
        ],
      ],
    );
  }
}

/// Status keenam API Connector
class KycBeApiStatusSection extends StatelessWidget {
  final bool? isRegisterApplicationInfoSuccess;
  final VerificationResultsResponse? beVerificationResults;
  final OcrResultsBeResponse? beOcrResults;
  final ICCardInfoResponse? beICCardInfo;
  final LivenessImagesResponse? beLivenessImages;
  final PhotosResponse? bePhotos;

  const KycBeApiStatusSection({
    super.key,
    this.isRegisterApplicationInfoSuccess,
    this.beVerificationResults,
    this.beOcrResults,
    this.beICCardInfo,
    this.beLivenessImages,
    this.bePhotos,
  });

  @override
  Widget build(BuildContext context) {
    final apis = [
      isRegisterApplicationInfoSuccess ?? false,
      beVerificationResults?.isSuccess ?? false,
      beOcrResults?.isSuccess ?? false,
      beICCardInfo?.isSuccess ?? false,
      beLivenessImages?.isSuccess ?? false,
      bePhotos?.isSuccess ?? false,
    ];
    final successCount = apis.where((ok) => ok).length;

    final Color sectionColor;
    if (successCount == 6) {
      sectionColor = Colors.green;
    } else if (successCount >= 3) {
      sectionColor = Colors.orange;
    } else {
      sectionColor = Colors.red;
    }

    return buildSection(
      title: 'BE API Status ($successCount/6)',
      icon: Icons.cloud_done,
      color: sectionColor,
      children: [
        buildApiStatusRow(
            'Register App Info', isRegisterApplicationInfoSuccess ?? false),
        buildApiStatusRow(
            'Verification Results', beVerificationResults?.isSuccess ?? false),
        buildApiStatusRow('OCR Results (BE)', beOcrResults?.isSuccess ?? false),
        buildApiStatusRow('IC Card Info', beICCardInfo?.isSuccess ?? false),
        buildApiStatusRow('Liveness Images', beLivenessImages?.isSuccess ?? false,
            count: beLivenessImages?.livenessImages?.length),
        buildApiStatusRow('Document Photos', bePhotos?.isSuccess ?? false,
            count: bePhotos?.idDocumentPhotos?.length),
      ],
    );
  }
}
