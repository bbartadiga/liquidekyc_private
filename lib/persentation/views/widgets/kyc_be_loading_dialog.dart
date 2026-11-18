import 'package:flutter/material.dart';

import '../../../data/services/kyc_be_api.dart';
import '../../viewmodels/kyc_viewmodel.dart';

class KycBeLoadingDialog extends StatefulWidget {
  final KycViewModel viewModel;
  final VoidCallback onComplete;
  final Function(String) onError;

  const KycBeLoadingDialog({
    super.key,
    required this.viewModel,
    required this.onComplete,
    required this.onError,
  });

  @override
  State<KycBeLoadingDialog> createState() => KycBeLoadingDialogState();
}

class KycBeLoadingDialogState extends State<KycBeLoadingDialog> {
  String _currentStep = 'Memproses...';
  
  final List<String> _beSteps = [
    'Register App Info',
    'Verification Results',
    'IC Card Info',
    'OCR Results',
    'Liveness Images',
    'Document Photos',
  ];
  
  final Set<String> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    // Set up progress listener
    widget.viewModel.addListener(_onProgressChanged);
    // Start fetching BE data
    _fetchBeData();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    if (!mounted) return;
    final step = widget.viewModel.currentProgressStep;
    final isLoading = widget.viewModel.isFetchingBeData;
    
    if (step.isNotEmpty) {
      setState(() {
        _currentStep = step;
        if (!isLoading && !_completedSteps.contains(step)) {
          _completedSteps.add(step);
        }
      });
    }
  }

  Future<void> _fetchBeData() async {
    try {
      // Call BE API methods with the viewModel's BE API
      final beApi = KycBeApi();
      
      // Set up progress callback
      beApi.onProgress = (step, isLoading) {
        if (mounted) {
          setState(() {
            _currentStep = step;
            if (!isLoading) {
              _completedSteps.add(step);
                }
          });
        }
      };

      final applicantId = widget.viewModel.currentApplicantId;
      if (applicantId == null) {
        widget.onError('Applicant ID not found');
        return;
      }

      // Fetch all BE data
      final futures = <Future>[];
      
      if (widget.viewModel.beVerificationResults == null) {
        futures.add(beApi.getVerificationResults(applicantId).then((r) {
          widget.viewModel.beVerificationResults = r;
        }));
      }
      
      if (widget.viewModel.beOcrResults == null) {
        futures.add(beApi.getOcrResultsFromBe(applicantId).then((r) {
          widget.viewModel.beOcrResults = r;
        }));
      }
      
      if (widget.viewModel.beICCardInfo == null) {
        futures.add(beApi.getICCardInfo(applicantId).then((r) {
          widget.viewModel.beICCardInfo = r;
        }));
      }
      
      if (widget.viewModel.beLivenessImages == null) {
        futures.add(beApi.getLivenessImages(applicantId).then((r) {
          widget.viewModel.beLivenessImages = r;
        }));
      }
      
      if (widget.viewModel.bePhotos == null) {
        futures.add(beApi.getPhotos(applicantId).then((r) {
          widget.viewModel.bePhotos = r;
        }));
      }

      // Wait for all
      await Future.wait(futures);
      
      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        widget.onError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _completedSteps.length / _beSteps.length;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Mengambil Data dari Server',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentStep,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_completedSteps.length / _beSteps.length * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            // Step list
            ...List.generate(_beSteps.length, (index) {
              final step = _beSteps[index];
              final isCompleted = _completedSteps.contains(step);
              final isCurrent = _currentStep == step && !isCompleted;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.radio_button_off,
                      size: 18,
                      color: isCompleted 
                          ? Colors.green 
                          : isCurrent 
                              ? Colors.blue 
                              : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      step,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted 
                            ? Colors.green 
                            : isCurrent 
                                ? Colors.blue 
                                : Colors.grey,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
