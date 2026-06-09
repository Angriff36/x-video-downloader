import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _wifiOnlyPrefKey = 'wifi_only_enabled';

/// Monitors network connectivity and enforces WiFi-only download policy.
///
/// When WiFi-only mode is enabled, downloads are paused when the device
/// switches to mobile data and auto-resumed when WiFi is reconnected.
class NetworkMonitor extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();

  /// Whether WiFi-only mode is enabled in settings.
  bool _wifiOnlyEnabled = false;
  bool get wifiOnlyEnabled => _wifiOnlyEnabled;

  /// Whether the device currently has a WiFi connection.
  bool _isOnWifi = true;
  bool get isOnWifi => _isOnWifi;

  /// Whether downloads should be allowed right now.
  /// True if WiFi-only is off, or if WiFi-only is on and device is on WiFi.
  bool get downloadsAllowed => !_wifiOnlyEnabled || _isOnWifi;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Callback invoked when network changes and downloads need to pause.
  VoidCallback? onDownloadsShouldPause;

  /// Callback invoked when network changes and downloads can resume.
  VoidCallback? onDownloadsCanResume;

  /// Initialize the monitor: load saved preference and start listening.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _wifiOnlyEnabled = prefs.getBool(_wifiOnlyPrefKey) ?? false;

    // Check current connectivity state
    final results = await _connectivity.checkConnectivity();
    _isOnWifi = results.any((r) => r == ConnectivityResult.wifi);

    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    notifyListeners();
  }

  /// Enable or disable WiFi-only mode and persist the setting.
  Future<void> setWifiOnly(bool enabled) async {
    if (_wifiOnlyEnabled == enabled) return;

    _wifiOnlyEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlyPrefKey, enabled);

    if (enabled && !_isOnWifi) {
      // Just enabled WiFi-only but not on WiFi — pause downloads
      onDownloadsShouldPause?.call();
    } else if (!enabled) {
      // Just disabled WiFi-only — resume any paused downloads
      onDownloadsCanResume?.call();
    }

    notifyListeners();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnWifi = _isOnWifi;
    _isOnWifi = results.any((r) => r == ConnectivityResult.wifi);

    if (_isOnWifi == wasOnWifi) return; // No change relevant to us

    if (_wifiOnlyEnabled) {
      if (_isOnWifi) {
        // Switched to WiFi — resume downloads
        onDownloadsCanResume?.call();
      } else {
        // Switched away from WiFi — pause downloads
        onDownloadsShouldPause?.call();
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
