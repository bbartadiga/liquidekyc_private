import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constant/liquid_constants.dart';
import '../../../data/services/kyc_be_api.dart';
import '../../viewmodels/kyc_viewmodel.dart';
import 'kyc_instruction_screen.dart';
import 'kyc_result_screen.dart';

class KycTokenScreen extends StatefulWidget {
  const KycTokenScreen({super.key});

  @override
  State<KycTokenScreen> createState() => _KycTokenScreenState();
}

class _KycTokenScreenState extends State<KycTokenScreen> {
  final _applicantIdController = TextEditingController(text: '111902224425');
  final _beApi = KycBeApi();
  bool _isLoading = false;

  @override
  void dispose() {
    _applicantIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Token'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.vpn_key, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Ambil Token dari BE',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan Applicant ID untuk mendapatkan token dari Backend Server.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _applicantIdController,
              decoration: InputDecoration(
                labelText: 'Applicant ID',
                hintText: 'Masukkan Applicant ID',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _getToken(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_download),
                        SizedBox(width: 8),
                        Text(
                          'Ambil Token',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Info:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Token bersifat unik per session KYC\n'
              '• Jika user cancel/timeout, perlu minta token baru\n'
              '• Applicant ID bisa digunakan berulang sampai verifikasi selesai',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getToken() async {
    final applicantId = _applicantIdController.text.trim();
    if (applicantId.isEmpty) {
      _showErrorDialog(
        title: 'Applicant ID Kosong',
        message: 'Masukkan Applicant ID terlebih dahulu',
        suggestion: 'Coba masukkan Applicant ID yang valid',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _beApi.applyForSdkToken(applicantId: applicantId);

      setState(() => _isLoading = false);

      if (response?.isSuccess == true && response?.token != null) {
        _showSuccessDialog(
          applicantId: response!.applicantId ?? applicantId,
          token: response.token!,
        );
      } else {
        _showErrorDialog(
          title: 'Gagal Dapat Token',
          message: response?.errorMessage ?? 'Unknown error',
          suggestion: 'Pastikan Applicant ID valid dan BE server berjalan',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      String errorTitle = 'Error Koneksi';
      String errorMessage = e.toString();
      String suggestion = '';

      if (e.toString().contains('No route to host') || e.toString().contains('SocketException')) {
        errorTitle = 'Tidak Terhubung ke Server';
        errorMessage = 'Tidak dapat menghubungi BE server\n\nAddress: 192.168.1.41:8080';
        suggestion = '• Pastikan HP dan server BE satu jaringan WiFi\n'
            '• Pastikan server BE sudah running\n'
            '• Cek firewall/port server';
      } else if (e.toString().contains('timeout')) {
        errorTitle = 'Koneksi Timeout';
        errorMessage = 'Server tidak merespon dalam waktu yang ditentukan';
        suggestion = '• Cek apakah server BE berjalan\n'
            '• Coba lagi beberapa saat';
      }

      _showErrorDialog(
        title: errorTitle,
        message: errorMessage,
        suggestion: suggestion,
      );
    }
  }

  void _showSuccessDialog({required String applicantId, required String token}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Berhasil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Token berhasil diperoleh!'),
            const SizedBox(height: 16),
            _buildInfoRow('Applicant ID', applicantId),
            const SizedBox(height: 8),
            _buildInfoRow('Token', token),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Token akan disimpan dan bisa digunakan untuk verifikasi',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              final viewModel = context.read<KycViewModel>();
              viewModel.setCredentials(
                applicantId: applicantId,
                token: token,
                sdkUrl: LiquidConfig.url,
              );
              Navigator.of(context).pop();
              _navigateToKycFlow(viewModel);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow),
                SizedBox(width: 4),
                Text('Simpan & Mulai KYC'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog({
    required String title,
    required String message,
    String? suggestion,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detail Error:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                    if (suggestion != null && suggestion.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Saran:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.router, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'BE Server: 192.168.1.41:8080\nPastikan server BE accessible dari HP',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _navigateToKycFlow(KycViewModel viewModel) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (ctx) => ChangeNotifierProvider.value(
          value: viewModel,
          child: KycInstructionScreen(
            method: viewModel.selectedMethod,
            documentType: viewModel.selectedDocumentType,
            onStart: () async {
              Navigator.of(ctx).pop();
              final result = await viewModel.startKyc();
              if (ctx.mounted) {
                if (result.isSuccess) {
                  Navigator.of(ctx).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => KycResultScreen(
                        isSuccess: true,
                        result: result,
                        documentResult: viewModel.documentResult,
                        faceResult: viewModel.faceResult,
                        chipResult: viewModel.chipVerificationResult,
                        beICCardInfo: viewModel.beICCardInfo,
                        onDone: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      ),
                    ),
                  );
                } else if (result.isCancelled) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Verifikasi dibatalkan')),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(viewModel.errorMessage ?? 'Verifikasi gagal'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            onBack: () => Navigator.of(ctx).popUntil((route) => route.isFirst),
          ),
        ),
      ),
      (route) => route.isFirst,
    );
  }
}