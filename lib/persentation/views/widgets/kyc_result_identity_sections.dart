import 'package:flutter/material.dart';

import '../../../core/constant/liquid_constants.dart';
import '../../../core/constant/liquid_mappings.dart';
import '../../../core/services/app_logger.dart';
import '../../../data/models/chip_result.dart';
import '../../../data/models/ic_card_info_response.dart';
import '../../../data/models/ocr_results_response.dart';
import 'kyc_result_widgets.dart';

class KycIdentityCard extends StatelessWidget {
  final bool showSdkData;
  final OcrResultsBeResponse? beOcrResults;
  final OcrResult? sdkOcr;
  final Nationality selectedNationality;
  final LiquidDocumentType selectedDocumentType;
  final LiquidChipDataModel? chipData;
  final LiquidDocumentType? actualDocumentType;
  final bool hasMismatch;

  const KycIdentityCard({
    super.key,
    required this.showSdkData,
    required this.selectedNationality,
    required this.selectedDocumentType,
    this.beOcrResults,
    this.sdkOcr,
    this.chipData,
    this.actualDocumentType,
    this.hasMismatch = false,
  });

  @override
  Widget build(BuildContext context) {
    final beOcr = beOcrResults;

    String? nationalityName;
    String? nationalityCode;
    String? documentTypeName;
    String? documentTypeCode;
    String? cardType;
    final String sourceTag;

    if (showSdkData) {
      // SDK tab: nationality dari SDK ocrResult, doc type dari config user
      nationalityName = resolveNationalityName(sdkOcr?.nationality) ??
          selectedNationality.displayName;
      nationalityCode = (sdkOcr?.nationality?.toUpperCase()) ??
          selectedNationality.name.toUpperCase();
      documentTypeName = selectedDocumentType.displayName;
      documentTypeCode = selectedDocumentType.value;
      // card_type tidak ada di OCR SDK — sumbernya chip data
      cardType = chipData?.residenceCardType ?? sdkOcr?.cardType;
      sourceTag = 'SDK + Config';
    } else {
      // BE tab: dua-duanya dari BE, fallback ke config user
      nationalityName = resolveNationalityName(beOcr?.nationality) ??
          selectedNationality.displayName;
      nationalityCode = (beOcr?.nationality?.toUpperCase()) ??
          selectedNationality.name.toUpperCase();
      documentTypeName = resolveDocumentTypeName(beOcr?.idDocumentType) ??
          selectedDocumentType.displayName;
      documentTypeCode = beOcr?.idDocumentType ?? selectedDocumentType.value;
      cardType = beOcr?.cardType;
      sourceTag = 'BE + Config';
    }

    final cardTypeName = resolveResidenceCardTypeName(cardType);
    final isGen2Plus = cardType != null && ['5', '6', '7', '8'].contains(cardType);

    // Detail Gen-2 cuma ada di residenceDocumentGen2Data
    final gen2 = chipData?.residenceDocumentGen2;
    final gen2Details = <(String, String?)>[
      ('Tipe Info', gen2?.residenceDocumentGen2InfoType),
      ('Izin Individual', gen2?.individualPermission),
      ('Izin Menyeluruh', gen2?.comprehensivePermissionCode),
      ('Berlaku s/d', gen2?.expireDateOfComprehensivePermission),
      ('Jenis Izin', gen2?.kindOfPermissionCode),
      ('Masa Tinggal', gen2?.stayPeriod),
      ('Tinggal s/d', gen2?.stayExpireDate),
      ('Status Tinggal', gen2?.stayUpdateStatus),
      ('Pekerjaan', gen2?.employmentRestriction),
      ('Status Asing', gen2?.immigrationCommissionerStatement),
      ('Kewarganegaraan', gen2?.nationalityCode),
      ('Status-resident', gen2?.residenceStatusCode),
      ('Tanggal Diizinkan', gen2?.permittedDate),
    ];

    appLogger.i('[IdentityCard] render | tab=${showSdkData ? "SDK" : "BE"} | source=$sourceTag | nationality="$nationalityName"($nationalityCode) | document="$documentTypeName"($documentTypeCode) | actual=${actualDocumentType?.value ?? "-"} | mismatch=$hasMismatch | card_type=$cardType');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Identitas Dokumen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (hasMismatch)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DOC MISMATCH',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              if (isGen2Plus)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'GEN-2',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sourceTag,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          if (cardTypeName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isGen2Plus
                    ? Colors.deepPurple.shade50
                    : Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isGen2Plus
                      ? Colors.deepPurple.shade200
                      : Colors.blueGrey.shade300,
                ),
              ),
              child: Text(
                'Card: $cardTypeName (code $cardType)',
                style: TextStyle(
                  fontSize: 11,
                  color: isGen2Plus
                      ? Colors.deepPurple.shade800
                      : Colors.blueGrey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (hasMismatch && actualDocumentType != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                'Kartu dibaca: ${actualDocumentType!.displayName} '
                '(${actualDocumentType!.value}) — bukan ${selectedDocumentType.displayName}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: buildIdentityField(
                  context,
                  label: 'Nationality',
                  value: nationalityName,
                  code: nationalityCode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildIdentityField(
                  context,
                  label: 'Jenis Dokumen',
                  value: documentTypeName,
                  code: documentTypeCode,
                ),
              ),
            ],
          ),
          if (gen2Details.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Gen2PermissionDetails(details: gen2Details),
          ],
        ],
      ),
    );
  }
}

/// Detail izin tinggal kartu Gen-2.
///
/// Data ini HANYA ada di `residenceDocumentGen2Data` — field izin tinggal
/// level atas selalu null untuk Gen-2, jadi harus dibaca dari sana.
class _Gen2PermissionDetails extends StatelessWidget {
  final List<(String, String?)> details;

  const _Gen2PermissionDetails({required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Izin Tinggal (Gen-2)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade800,
            ),
          ),
          const SizedBox(height: 6),
          for (final (label, value) in details)
            if (value != null && value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.deepPurple.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Ringkasan status 3 langkah: Document / IC Chip / Face
class KycStatusSummary extends StatelessWidget {
  final bool? documentStatus;
  final bool chipOk;
  final bool faceOk;

  const KycStatusSummary({
    super.key,
    required this.documentStatus,
    required this.chipOk,
    required this.faceOk,
  });

  @override
  Widget build(BuildContext context) {
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
          buildStatusItem(
            icon: Icons.article,
            label: 'Document',
            status: documentStatus,
          ),
          buildStatusItem(
            icon: Icons.nfc,
            label: 'IC Chip',
            status: chipOk,
          ),
          buildStatusItem(
            icon: Icons.face,
            label: 'Face',
            status: faceOk,
          ),
        ],
      ),
    );
  }
}

/// Data kartu dari OCR SDK (preview cepat)
class KycOcrSdkSection extends StatelessWidget {
  final OcrResult? sdkOcr;
  final LiquidChipDataModel? chipData;
  final String? ocrName;
  final String? ocrAddress;
  final String? ocrDateOfBirth;
  final String? ocrDocumentNumber;
  final String? ocrNationality;
  final String? ocrResidenceStatus;

  const KycOcrSdkSection({
    super.key,
    this.sdkOcr,
    this.chipData,
    this.ocrName,
    this.ocrAddress,
    this.ocrDateOfBirth,
    this.ocrDocumentNumber,
    this.ocrNationality,
    this.ocrResidenceStatus,
  });

  @override
  Widget build(BuildContext context) {
    final sdkCardType = resolveResidenceCardTypeName(
      chipData?.residenceCardType ?? sdkOcr?.cardType,
    );
    final cardTypeCode = chipData?.residenceCardType ?? sdkOcr?.cardType;

    return buildSection(
      title: 'Data Kartu (OCR - SDK Preview)',
      icon: Icons.article,
      color: Colors.blue,
      children: [
        buildDetailWithRomaji(
          label: 'Nama',
          original: ocrName,
          romajiSync: sdkOcr?.nameRomaji,
          romajiFuture: sdkOcr?.nameRomajiAsync,
        ),
        buildDetailWithRomaji(
          label: 'Alamat',
          original: ocrAddress,
          romajiSync: sdkOcr?.addressRomaji,
          romajiFuture: sdkOcr?.addressRomajiAsync,
          maxLines: 2,
        ),
        if (sdkOcr != null) ...buildAddressSplitRowsAsync(
          sdkOcr!,
          prefGetter: (o) => o.addressPref,
          cityGetter: (o) => o.addressCity,
          otherGetter: (o) => o.addressOther,
          prefSyncGetter: (o) => o.addressPrefRomaji,
          citySyncGetter: (o) => o.addressCityRomaji,
          otherSyncGetter: (o) => o.addressOtherRomaji,
          prefRomajiFuture: (o) => o.addressPrefRomajiAsync,
          cityRomajiFuture: (o) => o.addressCityRomajiAsync,
          otherRomajiFuture: (o) => o.addressOtherRomajiAsync,
        ),
        buildDetailPlaceholder('Tanggal Lahir', ocrDateOfBirth),
        buildDetailPlaceholder('No. Dokumen', ocrDocumentNumber),
        buildDetailPlaceholder('Nasionalitas', ocrNationality),
        if (chipData?.displayMyNumber != null)
          buildDetailPlaceholder('No. My Number', chipData!.displayMyNumber),
        buildDetailWithRomaji(
          label: 'Residence Status',
          original: ocrResidenceStatus,
          romajiSync: sdkOcr?.residentStatusRomaji,
          romajiFuture: sdkOcr?.residentStatusRomajiAsync,
        ),
        ...buildChangeDetectionRows(
          addressChanged: sdkOcr?.addressChanged,
          nameChanged: sdkOcr?.nameChanged,
          remarksExist: sdkOcr?.remarksExist,
        ),
        if (buildLicenseTypeRow(sdkOcr?.driversLicenseTypes) != null)
          buildLicenseTypeRow(sdkOcr?.driversLicenseTypes)!,
        if (sdkCardType != null)
          buildDetailPlaceholder('Card Type', '$sdkCardType ($cardTypeCode)'),
        const Divider(height: 8),
        buildSourceTag('SDK - Preview (Fast)'),
      ],
    );
  }
}

/// Data kartu dari Connector API (data official)
class KycOcrBeSection extends StatelessWidget {
  final OcrResultsBeResponse? ocr;
  final ICCardInfoResponse? ic;

  const KycOcrBeSection({super.key, this.ocr, this.ic});

  @override
  Widget build(BuildContext context) {
    // Local copy supaya null-promotion jalan (field widget tidak bisa dipromote)
    final ocrData = ocr;
    final icData = ic;

    final cardTypeName = resolveResidenceCardTypeName(ocrData?.cardType);
    final empRestr =
        resolveEmploymentRestrictionName(ocrData?.employmentRestrictionCode);

    final children = <Widget>[
      buildDetailWithRomaji(
        label: 'Nama',
        original: ocrData?.name,
        romajiSync: icData?.nameRomaji ?? ocrData?.nameRomaji,
        romajiFuture: icData?.nameKanjiRomajiAsync ?? ocrData?.nameRomajiAsync,
      ),
      buildDetailPlaceholder('Jenis Kelamin',
          ocrData?.sex != null ? formatSex(ocrData!.sex!) : null),
      buildDetailPlaceholder('Tanggal Lahir', ocrData?.birthday),
      buildDetailPlaceholder('No. Dokumen', ocrData?.idNumber),
      if (maskMyNumber(ocrData?.myNumber) != null)
        buildDetailPlaceholder('No. My Number', maskMyNumber(ocrData?.myNumber)),
      buildDetailWithRomaji(
        label: 'Alamat',
        original: ocrData?.address,
        romajiSync: icData?.addressRomaji ?? ocrData?.addressRomaji,
        romajiFuture: icData?.addressRomajiAsync ?? ocrData?.addressRomajiAsync,
        maxLines: 2,
      ),
      buildDetailWithRomaji(
        label: 'Alamat Lengkap',
        original: ocrData?.fullAddress,
        romajiSync: (icData != null)
            ? ([
                icData.addressPrefRomaji,
                icData.addressCityRomaji,
                icData.addressOtherRomaji
              ].where((s) => s != null && s.isNotEmpty).join(' '))
            : null,
        romajiFuture: (icData != null)
            ? joinAddressFuture(
                icData.addressPrefRomajiAsync,
                icData.addressCityRomajiAsync,
                icData.addressOtherRomajiAsync)
            : null,
        maxLines: 2,
      ),
      ...buildAddressSplitRowsWithRomajiAndAsync(
        prefOriginal: ocrData?.addressPref,
        prefRomajiSync: icData?.addressPrefRomaji,
        prefRomajiFuture: icData?.addressPrefRomajiAsync,
        cityOriginal: ocrData?.addressCity,
        cityRomajiSync: icData?.addressCityRomaji,
        cityRomajiFuture: icData?.addressCityRomajiAsync,
        otherOriginal: ocrData?.addressOther,
        otherRomajiSync: icData?.addressOtherRomaji,
        otherRomajiFuture: icData?.addressOtherRomajiAsync,
      ),
      buildDetailPlaceholder('Zip Code', ocrData?.zipCode),
      buildDetailPlaceholder('Dokumen', ocrData?.documentTypeDisplay),
      if (cardTypeName != null)
        buildDetailPlaceholder('Card Type', '$cardTypeName (${ocrData?.cardType})'),
      buildDetailPlaceholder('Nasionalitas', ocrData?.nationalityDisplay),
      if (ocrData?.nationalityCode3 != null)
        buildDetailPlaceholder(
            'Nasionalitas (3-letter)',
            '${resolveNationalityName3(ocrData!.nationalityCode3) ?? "-"} '
            '(${ocrData.nationalityCode3})'),
      buildDetailPlaceholder('Tgl Kadaluarsa',
          ocrData?.expireDate != null ? formatDate(ocrData!.expireDate!) : null),
      buildDetailPlaceholder('Tgl Terbit',
          ocrData?.issueDate != null ? formatDate(ocrData!.issueDate!) : null),
      buildDetailPlaceholder('Residence Status Code', ocrData?.residentStatusCode),
      buildDetailWithRomaji(
        label: 'Residence Status',
        original: ocrData?.residentStatus,
        romajiSync: ocrData?.residentStatusRomaji,
        romajiFuture: ocrData?.residentStatusRomajiAsync,
      ),
      _buildStayPeriodRow(),
      if (empRestr != null)
        buildDetailPlaceholder('Employment Restriction',
            '$empRestr (${ocrData?.employmentRestrictionCode})'),
      ...buildChangeDetectionRows(
        addressChanged: ocrData?.addressChanged,
        nameChanged: ocrData?.nameChanged,
        remarksExist: ocrData?.remarksExist,
      ),
      if (buildLicenseTypeRow(ocrData?.driversLicenseTypes) != null)
        buildLicenseTypeRow(ocrData?.driversLicenseTypes)!,
      buildDetailPlaceholder(
          'Stay Expire',
          ocrData?.stayExpireDate != null
              ? formatDate(ocrData!.stayExpireDate!)
              : null),
      const Divider(height: 8),
      buildSourceTag('BE - Official (Validated)'),
    ];

    return buildSection(
      title: 'Data Kartu (BE Official)',
      icon: Icons.verified_user,
      color: Colors.green,
      children: children,
    );
  }

  /// Stay period — split year/month/day kalau tersedia, fallback ke plain string
  Widget _buildStayPeriodRow() {
    final icData = ic;
    final ocrData = ocr;
    final hasSplit = icData?.stayPeriodYear != null ||
        icData?.stayPeriodMonth != null ||
        icData?.stayPeriodDay != null;
    if (!hasSplit && ocrData?.stayPeriod == null) {
      return buildDetailPlaceholder('Stay Period', null);
    }
    if (!hasSplit) {
      return buildDetailPlaceholder('Stay Period', ocrData?.stayPeriod);
    }
    final y = icData!.stayPeriodYear?.toString() ?? '?';
    final m = icData.stayPeriodMonth?.toString() ?? '?';
    final d = icData.stayPeriodDay?.toString() ?? '?';
    return buildDetailPlaceholder('Stay Period', '$y tahun $m bulan $d hari');
  }
}

/// Detail kartu Gen-2 / Specified Residence — muncul kalau cardType terdeteksi
class KycGen2CardSection extends StatelessWidget {
  final OcrResultsBeResponse? ocr;
  final ICCardInfoResponse? ic;

  const KycGen2CardSection({super.key, this.ocr, this.ic});

  @override
 Widget build(BuildContext context) {
    final cardType = ocr?.cardType ?? ic?.cardType;
    if (cardType == null) return const SizedBox.shrink();

    final cardName = resolveResidenceCardTypeName(cardType) ?? 'Unknown';
    final isGen2Plus = ['5', '6', '7', '8'].contains(cardType);

    return buildSection(
      title: 'Gen-2 Residence Info',
      icon: Icons.contact_emergency,
      color: isGen2Plus ? Colors.deepPurple : Colors.blueGrey,
      children: [
        buildDetailPlaceholder('Card Type', '$cardName ($cardType)'),
        buildDetailPlaceholder(' Nama (IC)', ic?.name),
        buildDetailPlaceholder('Alamat (IC)', ic?.address, maxLines: 2),
        buildDetailPlaceholder(' Nama (BE)', ocr?.name),
        buildDetailPlaceholder('Alamat (BE)', ocr?.address, maxLines: 2),
        if (ocr?.residentStatusCode != null || ic?.residentStatusCode != null)
          buildDetailPlaceholder('Resident Status (Code)',
              ocr?.residentStatusCode ?? ic?.residentStatusCode),
        if (ocr?.kindOfPermissionCode != null || ic?.kindOfPermissionCode != null)
          buildDetailPlaceholder('Permission Type (Code)',
              ocr?.kindOfPermissionCode ?? ic?.kindOfPermissionCode),
        if (ocr?.employmentRestrictionCode != null ||
            ic?.employmentRestrictionCode != null)
          buildDetailPlaceholder(' Employment Restriction',
              '${ocr?.employmentRestrictionCode ?? ic?.employmentRestrictionCode}'),
        if (ocr?.nationalityCode3 != null || ic?.nationalityCode3 != null)
          buildDetailPlaceholder(
              'Nationality (3-letter)', ocr?.nationalityCode3 ?? ic?.nationalityCode3),
        buildDetailPlaceholder('Stay Period (Year)', ic?.stayPeriodYear?.toString()),
        buildDetailPlaceholder('Stay Period (Month)', ic?.stayPeriodMonth?.toString()),
        buildDetailPlaceholder('Stay Period (Day)', ic?.stayPeriodDay?.toString()),
        const Divider(height: 8),
        buildSourceTag(isGen2Plus ? 'Gen-2 Era (2026+)' : 'Current Gen'),
      ],
    );
  }
}

/// Hasil verifikasi IC Chip (SDK atau BE)
