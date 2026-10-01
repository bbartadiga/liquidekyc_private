import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constant/liquid_constants.dart';
import '../../viewmodels/kyc_viewmodel.dart';

class KycConfigScreen extends StatelessWidget {
  const KycConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Verifikasi'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Consumer<KycViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDocumentTypeSection(context, viewModel),
                const SizedBox(height: 16),
                _buildFaceTypeSection(context, viewModel),
                const SizedBox(height: 16),
                _buildVerificationMethodSection(context, viewModel),
                const SizedBox(height: 24),
                _buildInfoCard(context, viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentTypeSection(BuildContext context, KycViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Jenis Dokumen IC',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...LiquidDocumentType.values.where((t) =>
                t == LiquidDocumentType.residenceCard ||
                t == LiquidDocumentType.driverLicense ||
                t == LiquidDocumentType.specialPermanentResidentCertificate
            ).map((docType) => _buildRadioOption(
                  context,
                  title: docType.displayName,
                  subtitle: _getDocumentDescription(docType),
                  isSelected: viewModel.selectedDocumentType == docType,
                  onTap: () => viewModel.setDocumentType(docType),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceTypeSection(BuildContext context, KycViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.face, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tipe Verifikasi Wajah',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRadioOption(
              context,
              title: 'Active Detection',
              subtitle: 'Gerakkan mulut dan nyalakan flash',
              icon: Icons.motion_photos_on,
              isSelected: viewModel.selectedFaceType == FaceVerificationType.active,
              onTap: () => viewModel.setFaceType(FaceVerificationType.active),
            ),
            const SizedBox(height: 8),
            _buildRadioOption(
              context,
              title: 'Passive Detection',
              subtitle: 'Tidak perlu aksi khusus',
              icon: Icons.face_retouching_natural,
              isSelected: viewModel.selectedFaceType == FaceVerificationType.passive,
              onTap: () => viewModel.setFaceType(FaceVerificationType.passive),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationMethodSection(BuildContext context, KycViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Metode Verifikasi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRadioOption(
              context,
              title: 'COMPLY_HE (Recommended)',
              subtitle: 'IC Card → OCR → Face',
              isSelected: viewModel.selectedMethod == VerificationMethod.complyHe,
              onTap: () => viewModel.setVerificationMethod(VerificationMethod.complyHe),
            ),
            const SizedBox(height: 8),
            _buildRadioOption(
              context,
              title: 'COMPLY_HO',
              subtitle: 'Document → Face',
              isSelected: viewModel.selectedMethod == VerificationMethod.complyHo,
              onTap: () => viewModel.setVerificationMethod(VerificationMethod.complyHo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, KycViewModel viewModel) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Konfigurasi Saat Ini',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Dokumen', viewModel.selectedDocumentType.displayName),
            _buildInfoRow('Metode', viewModel.selectedMethod.displayName),
            _buildInfoRow('Face', viewModel.selectedFaceType == FaceVerificationType.active ? 'Active' : 'Passive'),
            _buildInfoRow('Token', viewModel.hasDynamicCredentials ? 'Sudah ada' : 'Belum di-fetch'),
            _buildInfoRow('NFC', viewModel.nfcAvailable ? 'Tersedia' : 'Tidak tersedia'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getDocumentDescription(LiquidDocumentType docType) {
    switch (docType) {
      case LiquidDocumentType.residenceCard:
        return 'Kartu Izin Tinggal (Residence Card)';
      case LiquidDocumentType.specialPermanentResidentCertificate:
        return 'Sertifikat Penduduk Tetap Khusus';
      case LiquidDocumentType.driverLicense:
        return 'Surat Izin Mengemudi (SIM)';
      default:
        return 'Dokumen IC';
    }
  }
}