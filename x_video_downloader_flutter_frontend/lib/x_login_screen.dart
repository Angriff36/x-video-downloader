import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'auth_service.dart';

const _mobileUserAgent =
    'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

/// A full-screen WebView that loads the X (Twitter) login.
/// After the user logs in, it extracts the `auth_token` and `ct0` cookies and
/// saves them (as a combined cookie string) via AuthService under 'twitter'.
///
/// X requires BOTH cookies: `auth_token` is the session, and `ct0` is the CSRF
/// token that yt-dlp's Twitter extractor turns into the `x-csrf-token` header.
class XLoginScreen extends StatefulWidget {
  final AuthService authService;

  const XLoginScreen({super.key, required this.authService});

  @override
  State<XLoginScreen> createState() => _XLoginScreenState();
}

class _XLoginScreenState extends State<XLoginScreen> {
  bool _extracted = false;
  String _status =
      'Log in to X below. Your session will be captured automatically.';
  double _progress = 0;
  Timer? _cookiePoll;
  bool _popupOpen = false;

  @override
  void initState() {
    super.initState();
    // Google SSO hands the session back through a popup; page-load events on
    // the main WebView don't always fire afterward, so poll for the cookies.
    _cookiePoll = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _tryExtractCookies(),
    );
  }

  @override
  void dispose() {
    _cookiePoll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log in to X'),
        actions: [
          TextButton.icon(
            onPressed: _extracted ? null : _manualExtract,
            icon: const Icon(Icons.cookie, color: Colors.white70),
            label: const Text('Extract Cookie',
                style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _extracted ? Colors.green.shade100 : Colors.blue.shade100,
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
                      color: _extracted
                          ? Colors.green.shade900
                          : Colors.blue.shade900,
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
                url: WebUri('https://x.com/login'),
              ),
              initialSettings: InAppWebViewSettings(
                userAgent: _mobileUserAgent,
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                cacheEnabled: true,
                // "Sign in with Google" opens a popup window; without these
                // the popup silently fails and login dead-ends on a blank page.
                supportMultipleWindows: true,
                javaScriptCanOpenWindowsAutomatically: true,
              ),
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100.0);
              },
              onLoadStop: (controller, url) async {
                if (_extracted) return;
                await _tryExtractCookies();
              },
              onCreateWindow: (controller, createWindowAction) async {
                _showPopupWindow(createWindowAction.windowId);
                return true;
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Host a popup window (Google SSO) in a dialog-embedded WebView.
  /// It closes itself via window.close() when the SSO flow finishes.
  void _showPopupWindow(int? windowId) {
    _popupOpen = true;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(dialogContext).size.height * 0.8,
          child: InAppWebView(
            windowId: windowId,
            initialSettings: InAppWebViewSettings(
              userAgent: _mobileUserAgent,
              javaScriptEnabled: true,
              domStorageEnabled: true,
              supportMultipleWindows: true,
              javaScriptCanOpenWindowsAutomatically: true,
            ),
            onCloseWindow: (_) {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
            },
            onLoadStop: (_, __) async {
              if (!_extracted) await _tryExtractCookies();
            },
          ),
        ),
      ),
    ).then((_) => _popupOpen = false);
  }

  /// Read auth_token + ct0 from the x.com cookie store.
  Future<Map<String, String>> _readXCookies() async {
    final cookieManager = CookieManager.instance();
    final result = <String, String>{};
    // x.com is the current domain; twitter.com kept as a fallback for older sessions.
    for (final domain in ['https://x.com/', 'https://twitter.com/']) {
      final cookies = await cookieManager.getCookies(url: WebUri(domain));
      for (final cookie in cookies) {
        if (cookie.name == 'auth_token' && cookie.value.toString().isNotEmpty) {
          result['auth_token'] = cookie.value.toString();
        } else if (cookie.name == 'ct0' && cookie.value.toString().isNotEmpty) {
          result['ct0'] = cookie.value.toString();
        }
      }
    }
    return result;
  }

  Future<bool> _saveIfReady() async {
    final cookies = await _readXCookies();
    // auth_token is only set after a successful login; ct0 accompanies it.
    if ((cookies['auth_token'] ?? '').isEmpty) return false;

    final parts = <String>['auth_token=${cookies['auth_token']}'];
    if ((cookies['ct0'] ?? '').isNotEmpty) {
      parts.add('ct0=${cookies['ct0']}');
    }
    await widget.authService.saveToken(
      platform: 'twitter',
      accessToken: parts.join('; '),
    );
    return true;
  }

  Future<void> _tryExtractCookies() async {
    if (_extracted) return;
    try {
      if (await _saveIfReady()) {
        _cookiePoll?.cancel();
        setState(() {
          _extracted = true;
          _status = 'Session captured! You can now download X videos.';
        });
        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          final nav = Navigator.of(context);
          if (_popupOpen) nav.pop(); // close the SSO popup dialog first
          nav.pop(true); // close the login screen, signalling success
        }
      }
    } catch (e) {
      debugPrint('X cookie extraction error: $e');
    }
  }

  Future<void> _manualExtract() async {
    setState(() => _status = 'Checking cookies...');
    await _tryExtractCookies();
    if (!_extracted && mounted) {
      setState(() => _status =
          'No session found yet. Make sure you are fully logged in to X.');
    }
  }
}
