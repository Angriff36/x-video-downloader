import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'auth_service.dart';

/// A full-screen WebView that loads Instagram login.
/// After the user logs in, it automatically extracts the sessionid cookie
/// and saves it via AuthService.
class InstagramLoginScreen extends StatefulWidget {
  final AuthService authService;

  const InstagramLoginScreen({super.key, required this.authService});

  @override
  State<InstagramLoginScreen> createState() => _InstagramLoginScreenState();
}

class _InstagramLoginScreenState extends State<InstagramLoginScreen> {
  bool _extracted = false;
  String _status = 'Log in to Instagram below. Your session cookie will be captured automatically.';
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log in to Instagram'),
        actions: [
          TextButton.icon(
            onPressed: _extracted ? null : _manualExtract,
            icon: const Icon(Icons.cookie, color: Colors.white70),
            label: const Text('Extract Cookie', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _extracted
                ? Colors.green.shade100
                : Colors.blue.shade100,
            child: Row(
              children: [
                Icon(
                  _extracted ? Icons.check_circle : Icons.info_outline,
                  size: 18,
                  color: _extracted ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status,
                    style: TextStyle(
                      fontSize: 13,
                      color: _extracted ? Colors.green.shade900 : Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_progress < 1.0 && !_extracted)
            LinearProgressIndicator(value: _progress),
          // WebView
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri('https://www.instagram.com/accounts/login/'),
              ),
              initialSettings: InAppWebViewSettings(
                userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                cacheEnabled: true,
              ),
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100.0);
              },
              onLoadStop: (controller, url) async {
                if (_extracted) return;
                // Check cookies after every page load
                await _tryExtractCookie(controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _tryExtractCookie(InAppWebViewController controller) async {
    try {
      final cookieManager = CookieManager.instance();
      final cookies = await cookieManager.getCookies(url: WebUri('https://www.instagram.com/'));

      String? sessionId;
      for (final cookie in cookies) {
        if (cookie.name == 'sessionid') {
          sessionId = cookie.value;
          break;
        }
      }

      if (sessionId != null && sessionId.isNotEmpty) {
        setState(() {
          _extracted = true;
          _status = 'Cookie captured! You can now download Instagram videos.';
        });

        // Save the session ID
        await widget.authService.saveToken(
          platform: 'instagram',
          accessToken: sessionId,
        );

        // Pop back after a brief delay so user sees success
        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      debugPrint('Cookie extraction error: $e');
    }
  }

  Future<void> _manualExtract() async {
    setState(() => _status = 'Checking cookies...');
    // Get the current webview controller via the InAppWebView widget
    // This is handled by onLoadStop, so we just trigger a page check
    final cookieManager = CookieManager.instance();
    final cookies = await cookieManager.getCookies(url: WebUri('https://www.instagram.com/'));

    String? sessionId;
    for (final cookie in cookies) {
      if (cookie.name == 'sessionid') {
        sessionId = cookie.value;
        break;
      }
    }

    if (sessionId != null && sessionId.isNotEmpty) {
      setState(() {
        _extracted = true;
        _status = 'Cookie captured! You can now download Instagram videos.';
      });
      await widget.authService.saveToken(
        platform: 'instagram',
        accessToken: sessionId,
      );
      if (mounted) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop(true);
      }
    } else {
      setState(() => _status = 'No session cookie found yet. Make sure you are logged in to Instagram.');
    }
  }
}
