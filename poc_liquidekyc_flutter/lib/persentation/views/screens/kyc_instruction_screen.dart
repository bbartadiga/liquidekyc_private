import 'package:flutter/material.dart';
import '../../../core/constant/liquid_constants.dart';

class KycInstructionScreen extends StatefulWidget {
  final VerificationMethod method;
  final LiquidDocumentType documentType;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const KycInstructionScreen({
    super.key,
    required this.method,
    required this.documentType,
    required this.onStart,
    required this.onBack,
  });

  @override
  State<KycInstructionScreen> createState() => _KycInstructionScreenState();
}

class _KycInstructionScreenState extends State<KycInstructionScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_InstructionPage> get _pages {
    final List<_InstructionPage> pages = [];

    pages.add(_InstructionPage(
      title: 'Persiapan Dokumen',
      icon: Icons.document_scanner,
      description: 'Siapkan dokumen identitas Anda',
      details: [
        'Pastikan dokumen tidak rusak atau kedaluwarsa',
        'Letakkan dokumen di permukaan rata',
        'Pastikan permukaan bersih dari goresan',
      ],
    ));

    if (widget.method.requiresDocument) {
      pages.add(_InstructionPage(
        title: 'Panduan Pencahayaan',
        icon: Icons.light_mode,
        description: 'Atur pencahayaan untuk hasil terbaik',
        details: [
          'Pastikan ruangan memiliki pencahayaan cukup',
          'Hindari cahaya langsung yang menyilaukan',
          'Posisi cahaya di depan atau di samping dokumen',
        ],
      ));
    }

    if (widget.method.requiresFace) {
      pages.add(_InstructionPage(
        title: 'Panduan Wajah',
        icon: Icons.face,
        description: 'Persiapkan untuk verifikasi wajah',
        details: [
          'Lepas kacamata atau aksesoris wajah',
          'Pastikan wajah terlihat jelas',
          'Hindari background yang terlalu ramai',
        ],
      ));
    }

    if (widget.method.requiresIcCard) {
      pages.add(_InstructionPage(
        title: 'Panduan Chip IC',
        icon: Icons.nfc,
        description: 'Baca chip pada kartu',
        details: [
          'Letakkan kartu di permukaan datar',
          'Pastikan NFC pada perangkat aktif',
          'Jangan menggerakkan kartu saat proses membaca',
        ],
      ));
    }

    pages.add(_InstructionPage(
      title: 'Kerja Sama dengan iTrust',
      icon: Icons.verified_user,
      description: 'Teknologi Verifikasi',
      details: [
        'Teknologi iTrust dari Cybertrust digunakan untuk verifikasi keaslian dokumen',
        'Proses verifikasi dilakukan secara aman di dalam memori',
        'Data pribadi Anda akan diperlakukan sesuai kebijakan privasi',
      ],
      showCybertrust: true,
    ));

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Panduan eKYC'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / pages.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final page = pages[index];
                return _buildPage(page);
              },
            ),
          ),
          _buildBottomNav(pages.length),
        ],
      ),
    );
  }

  Widget _buildPage(_InstructionPage page) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            page.icon,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: page.details
                  .map((detail) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                detail,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          if (page.showCybertrust) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 40,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Powered by iTrust',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Teknologi verifikasi dari Cybertrust untuk keamanan dokumen Anda',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNav(int totalPages) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton.icon(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Prev'),
            )
          else
            const SizedBox(width: 100),
          Text('${_currentPage + 1} / $totalPages'),
          if (_currentPage < totalPages - 1)
            ElevatedButton.icon(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            )
          else
            ElevatedButton.icon(
              onPressed: widget.onStart,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Mulai'),
            ),
        ],
      ),
    );
  }
}

class _InstructionPage {
  final String title;
  final IconData icon;
  final String description;
  final List<String> details;
  final bool showCybertrust;

  _InstructionPage({
    required this.title,
    required this.icon,
    required this.description,
    required this.details,
    this.showCybertrust = false,
  });
}