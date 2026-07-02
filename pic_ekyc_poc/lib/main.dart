import 'package:flutter/material.dart';
import 'ekyc_webview_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PIC eKYC POC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _startEkyc(context),
              child: const Text("Mulai Verifikasi Identitas"),
            ),
            const SizedBox(height: 12),
            // Hapus button to prod
            ElevatedButton(
              onPressed: () => _startEkycTest(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text("[TEST] POC"),
            ),
          ],
        ),
      ),
    );
  }

  // TEST
  void _startEkycTest(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EkycWebViewPage(url: "https://google.com"),
      ),
    );
  }

  void _startEkyc(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EkycWebViewPage(),
      ),
    );

    if (!context.mounted) return;

    if (result is Map && result["status"] == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verifikasi identitas berhasil!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verifikasi dibatalkan."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}