import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constant/liquid_constants.dart';
import '../../../core/services/app_logger.dart';
import '../../../data/models/ic_card_info_response.dart';
import '../../../data/services/kyc_be_api.dart';
import '../../viewmodels/kyc_viewmodel.dart';
import '../../viewmodels/ordering_information_viewmodel.dart';
import '../widgets/kyc_be_loading_dialog.dart';
import '../widgets/kyc_loading_overlay.dart';
import 'ordering_information_screen.dart';

class KycHomeScreen extends StatefulWidget {
  const KycHomeScreen({super.key});

  @override
  State<KycHomeScreen> createState() => _KycHomeScreenState();
}

class _KycHomeScreenState extends State<KycHomeScreen> {
  final _beApi = KycBeApi();
  final _applicantIdController = TextEditingController(text: '111902224425');
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
        title: const Text('eKYC Verification'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Navigator.pushNamed(context, '/debug'),
            tooltip: 'Debug Logs',
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () => _navigateToOrderingInformation(context),
            tooltip: 'Ordering Information',
          ),
        ],
      ),
      body: Consumer<KycViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              _buildBody(context, viewModel),
              if (viewModel.isLoading || _isLoading)
                const KycLoadingOverlay(
                  title: 'Memuat...',
                  message: '',
                  step: KycStep.idle,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, KycViewModel viewModel) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Verifikasi Identitas',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan kartu IC dan foto wajah untuk verifikasi',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 48),
                    if (viewModel.hasDynamicCredentials)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text('Token Aktif', style: TextStyle(color: Colors.green.shade700)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomSection(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, KycViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.vpn_key, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Token Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const Spacer(),
                    if (viewModel.hasDynamicCredentials)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text('Aktif', style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _showInputDialog(context, viewModel),
                    icon: const Icon(Icons.edit),
                    label: Text(_applicantIdController.text.isEmpty ? 'Masukkan Applicant ID' : _applicantIdController.text),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _onStartVerification(context, viewModel),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow),
                              SizedBox(width: 8),
                              Text('Ambil Token & Mulai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInputDialog(BuildContext context, KycViewModel viewModel) {
    final controller = TextEditingController(text: _applicantIdController.text);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(sheetContext).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Applicant ID',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Masukkan Applicant ID',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                style: const TextStyle(fontSize: 16),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  _applicantIdController.text = controller.text;
                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _applicantIdController.text = controller.text;
                  Navigator.pop(sheetContext);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Simpan & Lanjut', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shortcut dari ikon mata: buka halaman Ordering Information.
  ///
  /// Data IC card dari BE tetap ditarik dulu biar halamannya nggak kosong,
  /// lalu field-nya diisi dari data chip / OCR yang sudah ada.
  void _navigateToOrderingInformation(BuildContext context) async {
    final applicantId = _applicantIdController.text.trim();
    if (applicantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan Applicant ID terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final icCardInfo = await _beApi.getICCardInfo(applicantId);

    setState(() => _isLoading = false);

    if (!context.mounted) return;

    _pushOrderingInformation(context, icCardInfo: icCardInfo);
  }

  /// Buka halaman Ordering Information dengan data IC chip / OCR.
  void _pushOrderingInformation(
    BuildContext context, {
    ICCardInfoResponse? icCardInfo,
    bool replace = false,
  }) {
    final viewModel = context.read<KycViewModel>();

    final route = MaterialPageRoute(
      builder: (_) => OrderingInformationScreen(
        chipData: viewModel.chipVerificationResult?.chipData,
        sdkOcr: viewModel.ocrResult,
        beOcr: viewModel.beOcrResults,
        beIcCardInfo: icCardInfo ?? viewModel.beICCardInfo,
        idDocumentInformation: viewModel.beIdDocumentInformation,
        processedInformation: viewModel.beProcessedInformation,
        documentType: viewModel.selectedDocumentType,
        initialNationality: OrderingInformationViewModel.nationalityLabel(
          viewModel.selectedNationality,
        ),
      ),
    );

    if (replace) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  void _onStartVerification(BuildContext context, KycViewModel viewModel) async {
    String applicantId = _applicantIdController.text.trim();

    if (applicantId.isEmpty) {
      _showInputDialog(context, viewModel);
      return;
    }

    // Ambil sebelum await — context ga boleh dipakai ulang setelah async gap
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      debugPrint('[STEP 1] User clicked "Ambil Token & Mulai"');
      debugPrint('  applicantId: $applicantId');
      debugPrint('  BYPASS_BE: ${LiquidConfig.bypassBe}');
      appLogger.i('[STEP 1] User clicked "Ambil Token & Mulai"');
      appLogger.i('  applicantId: $applicantId');
      appLogger.i('  BYPASS_BE: ${LiquidConfig.bypassBe}');

      // BYPASS_BE = true → skip BE, use hardcoded credentials
      if (LiquidConfig.bypassBe) {
        debugPrint('[STEP 2-4] BYPASS_BE=true - using hardcoded credentials');
        appLogger.i('[STEP 2-4] BYPASS_BE=true - using hardcoded credentials');

        viewModel.setCredentials(
          applicantId: LiquidConfig.applicantId,
          token: LiquidConfig.token,
          sdkUrl: LiquidConfig.url,
        );

        debugPrint('[STEP 4] Credentials set from hardcoded values');
        debugPrint('  ApplicantId: ${LiquidConfig.applicantId}');
        debugPrint('  Token: ${LiquidConfig.token}');
        appLogger.i('[STEP 4] Credentials set from hardcoded values');
        appLogger.i('  ApplicantId: ${LiquidConfig.applicantId}');
        appLogger.i('  Token: ${LiquidConfig.token}');

        setState(() => _isLoading = false);
        _navigateToKycFlow(context, viewModel);
        return;
      }

      // BYPASS_BE = false → call BE as normal
      debugPrint('[STEP 2] Calling BE to get token...');
      debugPrint('  URL: , baseURL: $_beApi._baseUrl');
      appLogger.i('[STEP 2] Calling BE to get token...');
      appLogger.i('  URL: ');

      final response = await _beApi.applyForSdkToken(applicantId: applicantId);

      debugPrint('[STEP 3] BE response received');
      debugPrint('  isSuccess: ${response?.isSuccess}');
      appLogger.i('[STEP 3] BE response received');
      appLogger.i('  isSuccess: ${response?.isSuccess}');

      if (response?.isSuccess == true && response?.token != null) {
        debugPrint('[STEP 4] BE response SUCCESS');
        debugPrint('  Token: ${response!.token}');
        debugPrint('  ApplicantId: ${response.applicantId ?? applicantId}');
        appLogger.i('[STEP 4] BE response SUCCESS');
        appLogger.i('  Token: ${response.token}');
        appLogger.i('  ApplicantId: ${response.applicantId ?? applicantId}');

        viewModel.setCredentials(
          applicantId: response.applicantId ?? applicantId,
          token: response.token!,
          sdkUrl: LiquidConfig.url,
        );

        debugPrint('[STEP 4] Credentials saved to ViewModel');
        appLogger.i('[STEP 4] Credentials saved to ViewModel');

        if (!context.mounted) return;
        setState(() => _isLoading = false);
        _navigateToKycFlow(context, viewModel);
      } else {
        if (!context.mounted) return;
        setState(() => _isLoading = false);

        final bool beUnavailable = (response?.errorMessage?.contains('No route to host') ?? false) ||
                                   (response?.errorMessage?.contains('SocketException') ?? false);

        if (beUnavailable && LiquidConfig.bypassBe) {
          debugPrint('[STEP 1-3] BE unavailable - BYPASS_BE=true, using hardcoded');
          debugPrint('  Using hardcoded credentials');
          appLogger.i('[STEP 1-3] BE unavailable - BYPASS_BE=true, using hardcoded');
          appLogger.i('  Using hardcoded credentials');
          messenger.showSnackBar(
            const SnackBar(
              content: Text('BE unreachable - using hardcoded credentials'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          viewModel.setCredentials(
            applicantId: LiquidConfig.applicantId,
            token: LiquidConfig.token,
            sdkUrl: LiquidConfig.url,
          );
          _navigateToKycFlow(context, viewModel);
          return;
        }

        debugPrint('[STEP 1-3] BE call FAILED');
        debugPrint('  Error: ${response?.errorMessage ?? "unknown"}');
        appLogger.e('[STEP 1-3] BE call FAILED');
        appLogger.e('  Error: ${response?.errorMessage ?? "unknown"}');
        messenger.showSnackBar(
          SnackBar(
            content: Text(response?.errorMessage ?? 'Gagal mendapat token'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isLoading = false);

      final errorStr = e.toString();
      debugPrint('[STEP 1-3] Catch error: $errorStr');
      appLogger.i('[STEP 1-3] Catch error: $errorStr');
      final bool beUnavailable = errorStr.contains('No route to host') || 
                                 errorStr.contains('SocketException');

      debugPrint('[STEP 1-3] beUnavailable=$beUnavailable, BYPASS_BE=${LiquidConfig.bypassBe}');
      appLogger.i('  beUnavailable=$beUnavailable, BYPASS_BE=${LiquidConfig.bypassBe}');

      if (beUnavailable && LiquidConfig.bypassBe) {
        debugPrint('[STEP 1-3] BE unavailable - BYPASS_BE=true, using hardcoded');
        debugPrint('  Using hardcoded credentials');
        appLogger.i('[STEP 1-3] BE unavailable - BYPASS_BE=true, using hardcoded');
        appLogger.i('  Using hardcoded credentials');
        messenger.showSnackBar(
          const SnackBar(
            content: Text('BE unreachable - using hardcoded credentials'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        viewModel.setCredentials(
          applicantId: LiquidConfig.applicantId,
          token: LiquidConfig.token,
          sdkUrl: LiquidConfig.url,
        );
        _navigateToKycFlow(context, viewModel);
        return;
      }

      debugPrint('[STEP 1-3] Error: $e');
      appLogger.e('[STEP 1-3] Error: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Dokumen yang SDK-nya nanya kredensial kartu (bisa Salah ketik).
  bool _needsChipCredentialWarning(
    LiquidDocumentType documentType,
    VerificationMethod method,
  ) {
    // Method yang nggak baca chip (FRONT, COMPLY_TO, ...) nggak nanya
    // kredensial sama sekali → nggak ada risiko kunci kartu.
    if (!method.requiresIcCard) return false;
    return documentType.value.startsWith('MY_NUMBER_CARD') ||
        documentType == LiquidDocumentType.driverLicense;
  }

  /// Dialog pre-flight: kasih tahu user persis data apa yang diminta SDK
  /// dan apa risikonya, sebelum kartu disentuh.
  Future<bool> _showChipCredentialWarning(BuildContext context) async {
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.credit_card, color: Colors.deepOrange, size: 32),
        title: const Text('Sebelum Mulai'),
        content: SingleChildScrollView(
          child: Text(
            'SDK akan meminta data yang tertera di kartu:\n'
            '• Tanggal lahir\n'
            '• Tanggal berlaku\n'
            '• Kode keamanan (4 digit kecil di pojok kartu)\n\n'
            'Data ini dibandingkan dengan hasil baca kartu. '
            'Kalau tidak cocok, kartu My Number Card kehilangan 1 jatah percobaan. '
            'Setelah beberapa kali gagal, kartu terkunci dan harus dibuka '
            'di kantor kecamatan.\n\n'
            'Pastikan kartu terlihat jelas dan data yang diketik sama persis '
            'dengan yang tercetak.',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    appLogger.i(
      '[STEP 6] Chip credential warning | proceed=$proceed',
    );
    return proceed ?? false;
  }

  void _navigateToKycFlow(BuildContext context, KycViewModel viewModel) async {
    debugPrint('[STEP 5] SKIP InstructionScreen - starting KYC directly');
    debugPrint('  Method: ${viewModel.selectedMethod.displayName}');
    debugPrint('  Document: ${viewModel.selectedDocumentType.displayName}');
    debugPrint('  Credentials: applicantId=${viewModel.currentApplicantId}, tokenLen=${viewModel.currentToken?.length ?? 0}');
    appLogger.i('[STEP 5] SKIP InstructionScreen - starting KYC directly');
    appLogger.i('  Method: ${viewModel.selectedMethod.displayName}');
    appLogger.i('  Document: ${viewModel.selectedDocumentType.displayName}');
    appLogger.i('  Credentials: applicantId=${viewModel.currentApplicantId}, tokenLen=${viewModel.currentToken?.length ?? 0}');

    debugPrint('[STEP 6] Starting KYC verification...');
    appLogger.i('[STEP 6] Starting KYC verification...');

    // =========================================
    // PHASE 1: SDK Verification (no loading overlay yet)
    // =========================================

    // Peringatan sebelum masuk flow chip: counter percobaan ada di IC chip
    // kartu, jadi salah ketik kredensial bisa mengunci kartu beneran.
    if (_needsChipCredentialWarning(
      viewModel.selectedDocumentType,
      viewModel.selectedMethod,
    )) {
      final proceed = await _showChipCredentialWarning(context);
      if (!proceed) return;
    }

    final result = await viewModel.startKyc();
    
    if (!context.mounted) return;

    // Check if SDK failed
    if (!result.isSuccess) {
      if (result.isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verifikasi dibatalkan')),
        );
      } else if (viewModel.cardLockRisk) {
        // Risiko kunci kartu fisik → dialog, bukan snackbar yang keburu hilang.
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
            title: const Text('Verifikasi Gagal'),
            content: SingleChildScrollView(child: Text(viewModel.errorMessage ?? 'Verifikasi gagal')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Verifikasi gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // =========================================
    // PHASE 2: BE API Fetch (show loading overlay HERE)
    // =========================================
    debugPrint('[PHASE 2] SDK completed - fetching BE data...');
    appLogger.i('[PHASE 2] SDK completed - fetching BE data...');

    // Show loading overlay with progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => KycBeLoadingDialog(
        viewModel: viewModel,
        onComplete: () {
          Navigator.pop(dialogContext);
          // SDK + BE selesai → langsung ke form Ordering Information yang
          // field-nya diisi dari data IC chip.
          if (context.mounted) {
            _pushOrderingInformation(context, replace: true);
          }
        },
        onError: (error) {
          Navigator.pop(dialogContext);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengambil data: $error'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }
}

// =========================================
// BE Loading Dialog with Progress
