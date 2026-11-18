import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constant/liquid_constants.dart';
import '../../viewmodels/kyc_viewmodel.dart';
import 'kyc_home_screen.dart';

class KycConfigScreen extends StatefulWidget {
  const KycConfigScreen({super.key});

  @override
  State<KycConfigScreen> createState() => _KycConfigScreenState();
}

class _KycConfigScreenState extends State<KycConfigScreen> {
  Nationality _nationality = Nationality.indonesia;
  LiquidDocumentType? _docType;

  @override
  void initState() {
    super.initState();
    _docType = _nationality.allowedDocuments.first;
  }

  void _onNationalityChanged(Nationality? value) {
    if (value == null || value == _nationality) return;
    setState(() {
      _nationality = value;
      _docType = value.allowedDocuments.first;
    });
  }

  void _onSubmit() {
    if (_docType == null) return;
    final viewModel = context.read<KycViewModel>();
    viewModel.setNationality(_nationality);
    // Project ini HANYA pakai COMPLY_HE (IC Card + Face).
    viewModel.setVerificationMethod(VerificationMethod.complyHe);
    viewModel.setDocumentType(_docType!);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KycHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Verifikasi'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Dokumen',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sesuaikan dengan kewarganegaraan Anda',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Kewarganegaraan',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Nationality>(
                        initialValue: _nationality,
                        isExpanded: true,
                        decoration: _dropdownDecoration(theme),
                        items: Nationality.values
                            .map((n) => DropdownMenuItem<Nationality>(
                                  value: n,
                                  child: Text(n.displayName),
                                ))
                            .toList(),
                        onChanged: _onNationalityChanged,
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Tipe Dokumen',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<LiquidDocumentType>(
                        initialValue: _docType,
                        isExpanded: true,
                        decoration: _dropdownDecoration(theme),
                        items: _nationality.allowedDocuments
                            .map((d) => DropdownMenuItem<LiquidDocumentType>(
                                  value: d,
                                  child: Text(d.displayName),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _docType = value),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _docType == null ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(ThemeData theme) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
    );
  }
}
