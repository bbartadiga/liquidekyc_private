import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class EkycWebViewPage extends StatefulWidget {
  final String? url;
  const EkycWebViewPage({super.key, this.url});

  @override
  State<EkycWebViewPage> createState() => _EkycWebViewPageState();
}

class _EkycWebViewPageState extends State<EkycWebViewPage> {
  static const String _productionUrl = "https://kycpoc.duckdns.org/kycpoc.html";
  static const String _redirectSignalUrl = "https://kycpoc.duckdns.org/kycpoc.html";

  /// Launch URL di luar webview (Play Store, native app, deep link, dsb.)
  static Future<void> _launchExternalUrl(String rawUrl) async {
    debugPrint('[_launchExternalUrl] url: $rawUrl');
    try {
      if (rawUrl.startsWith('intent://')) {
        final packageMatch = RegExp(r'package=([^;]+)').firstMatch(rawUrl);
        final schemeMatch = RegExp(r'scheme=([^;]+)').firstMatch(rawUrl);
        if (packageMatch != null) {
          final package = packageMatch.group(1)!;
          final appScheme = schemeMatch?.group(1);
          if (appScheme != null) {
            final appUri = Uri.parse(
              '$appScheme://${rawUrl.substring('intent://'.length).split('#').first}',
            );
            if (await canLaunchUrl(appUri)) {
              await launchUrl(appUri, mode: LaunchMode.externalApplication);
              return;
            }
          }
          final marketUri = Uri.parse('market://details?id=$package');
          if (await canLaunchUrl(marketUri)) {
            await launchUrl(marketUri, mode: LaunchMode.externalApplication);
          } else {
            await launchUrl(
              Uri.parse('https://play.google.com/store/apps/details?id=$package'),
              mode: LaunchMode.externalApplication,
            );
          }
        }
        return;
      }

      final uri = Uri.parse(rawUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[_launchExternalUrl] error: $e');
    }
  }

  /// Buka popup WebView dengan windowId untuk menangkap URL dari window.open()
  void _handlePopupWindow(int windowId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PopupWebView(
        windowId: windowId,
        onExternalUrl: (url) async {
          // Tutup popup dulu, baru launch app
          if (ctx.mounted) Navigator.pop(ctx);
          await _launchExternalUrl(url);
        },
        onClose: () {
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  InAppWebViewSettings get _webSettings => InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        javaScriptCanOpenWindowsAutomatically: true,
        supportMultipleWindows: true,
        // Hapus marker "(wv)" agar halaman ProTech tidak disable deep link
        userAgent:
            "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36",
      );

  @override
  Widget build(BuildContext context) {
    final loadUrl = widget.url ?? _productionUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Identitas'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, "cancelled"),
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(loadUrl)),
        initialSettings: _webSettings,

        onPermissionRequest: (controller, request) async {
          return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT,
          );
        },

        // Handle window.open() — URL-nya null di sini, butuh child WebView
        onCreateWindow: (controller, createWindowAction) async {
          debugPrint('[onCreateWindow] windowId: ${createWindowAction.windowId}');
          _handlePopupWindow(createWindowAction.windowId);
          return true;
        },

        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final url = navigationAction.request.url.toString();
          debugPrint('[shouldOverrideUrlLoading] url: $url');

          // Play Store → launch langsung
          if (url.startsWith('market://') ||
              url.startsWith('https://play.google.com/store') ||
              url.startsWith('http://play.google.com/store')) {
            await _launchExternalUrl(url);
            return NavigationActionPolicy.CANCEL;
          }

          // intent:// dan custom scheme lain → launch external
          if (!url.startsWith('http://') && !url.startsWith('https://')) {
            await _launchExternalUrl(url);
            return NavigationActionPolicy.CANCEL;
          }

          // Redirect signal verifikasi selesai
          if (url.startsWith(_redirectSignalUrl)) {
            final uri = Uri.parse(url);
            final identity = uri.queryParameters['Identity'];
            Navigator.pop(context, {
              "status": "success",
              "identity": identity,
            });
            return NavigationActionPolicy.CANCEL;
          }

          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}

/// WebView tersembunyi untuk menangkap URL dari window.open()
class _PopupWebView extends StatelessWidget {
  final int windowId;
  final Future<void> Function(String url) onExternalUrl;
  final VoidCallback onClose;

  const _PopupWebView({
    required this.windowId,
    required this.onExternalUrl,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink(
      child: InAppWebView(
        // windowId menghubungkan WebView ini ke popup yang diminta halaman
        windowId: windowId,
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          userAgent:
              "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36",
        ),

        // Di sinilah URL asli dari window.open() akan muncul
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final url = navigationAction.request.url.toString();
          debugPrint('[PopupWebView] shouldOverrideUrlLoading url: $url');

          // ProTech android.html → buka di Chrome Custom Tab (bukan WebView)
          // Chrome Custom Tab tidak punya sec-ch-ua "Android WebView", jadi
          // halaman ProTech akan detect Chrome dan aktifkan deep link ke native app
          if (url.contains('app.protechidchecker.com')) {
            onClose(); // tutup invisible popup WebView
            try {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.inAppBrowserView, // Chrome Custom Tab
              );
            } catch (e) {
              debugPrint('[PopupWebView] error launch custom tab: $e');
              // Fallback ke external browser
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            }
            return NavigationActionPolicy.CANCEL;
          }

          // Custom scheme / intent:// / market:// → launch native app
          if (!url.startsWith('http://') ||
              url.startsWith('market://') ||
              url.startsWith('https://play.google.com/store')) {
            await onExternalUrl(url);
            return NavigationActionPolicy.CANCEL;
          }

          // https lain → tetap allow di popup
          return NavigationActionPolicy.ALLOW;
        },

        onLoadStart: (controller, url) {
          debugPrint('[PopupWebView] onLoadStart url: $url');
        },

        onCloseWindow: (controller) {
          debugPrint('[PopupWebView] onCloseWindow');
          onClose();
        },
      ),
    );
  }
}