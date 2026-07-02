import 'package:flutter/material.dart';
import 'package:prism_ekyc/prism_ekyc.dart';
import 'package:pocprism_ekyc/core/api_uri.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'POC PrismEkyc Demo',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POC PrismEkyc Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildButtonEkyc(context),
      ),
    );
  }

  Widget _buildButtonEkyc(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        onPressed: () async {
          print('API Key used: ${ApiUri.apiKey}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (navContext) => PrismEkyc.screen(
                PrismEkycConfig(
                  baseUrl: ApiUri.baseUrl,
                  apiKey: ApiUri.apiKey,
                  onComplete: (EkycResult result) {
                    print('Name: ${result.formData.fullName}');
                    print('Card #: ${result.formData.cardNumber}');
                    print('NFC address: ${result.nfcData?.chipAddress}');
                    print('Face verified: ${result.faceVerified}');
                  },
                ),
              ),
            ),
          );
        },
        child: const Text('Start eKYC'),
      ),
    );
  }
}
