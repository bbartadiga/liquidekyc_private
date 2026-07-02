import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constant/liquid_constants.dart';
import '../../../core/services/app_logger.dart';
import '../../../data/services/kyc_be_api.dart';
import '../../viewmodels/kyc_viewmodel.dart';
import '../widgets/kyc_loading_overlay.dart';
import 'kyc_config_screen.dart';
import 'kyc_instruction_screen.dart';
import 'kyc_result_screen.dart';

class KycHomeScreen extends StatefulWidget {
  KycHomeScreen({super.key});

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
            onPressed: () => _navigateToTestResult(context),
            tooltip: 'Test Result Screen',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToConfig(context),
            tooltip: 'Pengaturan',
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
                Text('BE: 192.168.1.41:8080', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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

  void _navigateToConfig(BuildContext context) {
    final viewModel = context.read<KycViewModel>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: viewModel,
          child: const KycConfigScreen(),
        ),
      ),
    );
  }

  void _navigateToTestResult(BuildContext context) async {
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => KycResultScreen(
          isSuccess: true,
          beICCardInfo: icCardInfo,
          onDone: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  void _onStartVerification(BuildContext context, KycViewModel viewModel) async {
    String applicantId = _applicantIdController.text.trim();
    
    if (applicantId.isEmpty) {
      _showInputDialog(context, viewModel);
      return;
    }
    if (applicantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan Applicant ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      debugPrint('[STEP 1] User clicked "Ambil Token & Mulai"');
      debugPrint('  applicantId: $applicantId');
      debugPrint('  BYPASS_BE: ${LiquidConfig.BYPASS_BE}');
      appLogger.i('[STEP 1] User clicked "Ambil Token & Mulai"');
      appLogger.i('  applicantId: $applicantId');
      appLogger.i('  BYPASS_BE: ${LiquidConfig.BYPASS_BE}');

      // BYPASS_BE = true → skip BE, use hardcoded credentials
      if (LiquidConfig.BYPASS_BE) {
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
      debugPrint('  URL: http://192.168.1.41:8080/v1/sdk/applications');
      appLogger.i('[STEP 2] Calling BE to get token...');
      appLogger.i('  URL: http://192.168.1.41:8080/v1/sdk/applications');

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

        setState(() => _isLoading = false);
        _navigateToKycFlow(context, viewModel);
      } else {
        setState(() => _isLoading = false);

        final bool beUnavailable = (response?.errorMessage?.contains('No route to host') ?? false) ||
                                   (response?.errorMessage?.contains('SocketException') ?? false);

        if (beUnavailable && LiquidConfig.BYPASS_BE) {
          debugPrint('[STEP 1-3] BE unavailable - BYPASS_BE=true, using hardcoded');
          debugPrint('  Using hardcoded credentials');
          appLogger.i('[STEP 1-3] BE unavailable - BYPASS_BE=true, using hardcoded');
          appLogger.i('  Using hardcoded credentials');
          ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?.errorMessage ?? 'Gagal mendapat token'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      final errorStr = e.toString();
      debugPrint('[STEP 1-3] Catch error: $errorStr');
      appLogger.i('[STEP 1-3] Catch error: $errorStr');
      final bool beUnavailable = errorStr.contains('No route to host') || 
                                 errorStr.contains('SocketException');

      debugPrint('[STEP 1-3] beUnavailable=$beUnavailable, BYPASS_BE=${LiquidConfig.BYPASS_BE}');
      appLogger.i('  beUnavailable=$beUnavailable, BYPASS_BE=${LiquidConfig.BYPASS_BE}');

      if (beUnavailable && LiquidConfig.BYPASS_BE) {
        debugPrint('[STEP 1-3] BE unavailable - BYPASS_BE=true, using hardcoded');
        debugPrint('  Using hardcoded credentials');
        appLogger.i('[STEP 1-3] BE unavailable - BYPASS_BE=true, using hardcoded');
        appLogger.i('  Using hardcoded credentials');
        ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

    final result = await viewModel.startKyc();
    if (context.mounted) {
      if (result.isSuccess) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => KycResultScreen(
              isSuccess: true,
              result: result,
              documentResult: viewModel.documentResult,
              faceResult: viewModel.faceResult,
              chipResult: viewModel.chipVerificationResult,
              beICCardInfo: viewModel.beICCardInfo,
              ocrName: viewModel.ocrResult?.name,
              ocrAddress: viewModel.ocrResult?.address,
              ocrDateOfBirth: viewModel.ocrResult?.dateOfBirth,
              ocrDocumentNumber: viewModel.ocrResult?.documentNumber,
              onDone: () => Navigator.of(ctx).popUntil((route) => route.isFirst),
            ),
          ),
        );
      } else if (result.isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verifikasi dibatalkan')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Verifikasi gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}