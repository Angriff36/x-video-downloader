import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'platform_auth_config.dart';

/// Stored OAuth token data for a platform.
class AuthToken {
  final String platform;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? tokenType;
  final List<String> scopes;

  const AuthToken({
    required this.platform,
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.tokenType,
    this.scopes = const [],
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isValid => accessToken.isNotEmpty && !isExpired;

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt?.toIso8601String(),
        'token_type': tokenType,
        'scopes': scopes,
      };

  factory AuthToken.fromJson(Map<String, dynamic> json) => AuthToken(
        platform: json['platform'] as String,
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String?,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
        tokenType: json['token_type'] as String?,
        scopes: (json['scopes'] as List?)?.cast<String>() ?? [],
      );
}

/// Result of an auth operation.
class AuthResult {
  final bool success;
  final String? error;
  final AuthToken? token;

  const AuthResult({required this.success, this.error, this.token});

  factory AuthResult.ok(AuthToken token) =>
      AuthResult(success: true, token: token);
  factory AuthResult.fail(String error) =>
      AuthResult(success: false, error: error);
}

/// Manages OAuth authentication for video platforms.
///
/// Handles login, token storage, refresh, and logout for each platform.
/// Tokens are stored securely using flutter_secure_storage and automatically
/// refreshed when expired.
class AuthService extends ChangeNotifier {
  static const _storagePrefix = 'auth_token_';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  /// Currently loaded tokens, keyed by platform name.
  final Map<String, AuthToken> _tokens = {};

  /// Loading state per platform.
  final Set<String> _loadingPlatforms = {};

  /// Get all loaded tokens.
  Map<String, AuthToken> get tokens => Map.unmodifiable(_tokens);

  /// Check if a platform is currently loading (authenticating).
  bool isLoading(String platform) => _loadingPlatforms.contains(platform);

  /// Check if a platform has a valid (non-expired) token.
  bool isAuthenticated(String platform) {
    final token = _tokens[platform];
    return token != null && token.isValid;
  }

  /// Get the token for a platform, or null.
  AuthToken? tokenFor(String platform) => _tokens[platform];

  /// Get a valid access token for a platform, refreshing if needed.
  Future<String?> getValidAccessToken(String platform) async {
    final token = _tokens[platform];
    if (token == null) return null;
    if (token.isValid) return token.accessToken;

    // Try to refresh
    if (token.refreshToken != null) {
      final result = await refreshToken(platform);
      return result.success ? result.token?.accessToken : null;
    }
    return null;
  }

  /// Initialize by loading all stored tokens from secure storage.
  Future<void> init() async {
    for (final config in PlatformAuthConfig.all) {
      await _loadToken(config.platform);
    }
  }

  /// Start OAuth login flow for a platform.
  Future<AuthResult> login(PlatformAuthConfig config) async {
    if (_loadingPlatforms.contains(config.platform)) {
      return AuthResult.fail('Authentication already in progress');
    }

    _loadingPlatforms.add(config.platform);
    notifyListeners();

    try {
      final AuthorizationTokenRequest request;

      if (config.discoveryUrl.isNotEmpty) {
        request = AuthorizationTokenRequest(
          config.clientId,
          config.redirectUrl,
          discoveryUrl: config.discoveryUrl,
          scopes: config.scopes,
          clientSecret: config.clientSecret.isNotEmpty
              ? config.clientSecret
              : null,
        );
      } else {
        request = AuthorizationTokenRequest(
          config.clientId,
          config.redirectUrl,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: config.authorizationEndpoint,
            tokenEndpoint: config.tokenEndpoint,
          ),
          scopes: config.scopes,
          clientSecret: config.clientSecret.isNotEmpty
              ? config.clientSecret
              : null,
        );
      }

      final response = await _appAuth.authorizeAndExchangeCode(request);

      final token = AuthToken(
        platform: config.platform,
        accessToken: response.accessToken ?? '',
        refreshToken: response.refreshToken,
        expiresAt: response.accessTokenExpirationDateTime,
        tokenType: 'Bearer',
        scopes: config.scopes,
      );

      if (token.accessToken.isEmpty) {
        return AuthResult.fail('Empty access token received');
      }

      await _saveToken(token);
      _tokens[config.platform] = token;
      notifyListeners();

      return AuthResult.ok(token);
    } catch (e) {
      debugPrint('OAuth error for ${config.platform}: $e');
      return AuthResult.fail(_userFriendlyError(e));
    } finally {
      _loadingPlatforms.remove(config.platform);
      notifyListeners();
    }
  }

  /// Refresh an expired token using the stored refresh token.
  Future<AuthResult> refreshToken(String platform) async {
    final token = _tokens[platform];
    if (token?.refreshToken == null) {
      return AuthResult.fail('No refresh token available');
    }

    final config = PlatformAuthConfig.forPlatform(platform);
    if (config == null) {
      return AuthResult.fail('Unknown platform');
    }

    try {
      final response = await _appAuth.token(
        TokenRequest(
          config.clientId,
          config.redirectUrl,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: config.authorizationEndpoint,
            tokenEndpoint: config.tokenEndpoint,
          ),
          refreshToken: token!.refreshToken,
          scopes: config.scopes,
          clientSecret: config.clientSecret.isNotEmpty
              ? config.clientSecret
              : null,
        ),
      );

      final newToken = AuthToken(
        platform: platform,
        accessToken: response.accessToken ?? '',
        refreshToken: response.refreshToken ?? token.refreshToken,
        expiresAt: response.accessTokenExpirationDateTime,
        tokenType: 'Bearer',
        scopes: config.scopes,
      );

      await _saveToken(newToken);
      _tokens[platform] = newToken;
      notifyListeners();

      return AuthResult.ok(newToken);
    } catch (e) {
      debugPrint('Token refresh error for $platform: $e');
      // If refresh fails, mark as needing re-login but don't remove token
      return AuthResult.fail('Token refresh failed. Please log in again.');
    }
  }

  /// Log out from a platform by removing its stored token.
  Future<void> logout(String platform) async {
    _tokens.remove(platform);
    await _storage.delete(key: '$_storagePrefix$platform');
    notifyListeners();
  }

  /// Log out from all platforms.
  Future<void> logoutAll() async {
    for (final platform in _tokens.keys.toList()) {
      await _storage.delete(key: '$_storagePrefix$platform');
    }
    _tokens.clear();
    notifyListeners();
  }

  /// Load a stored token from secure storage.
  Future<void> _loadToken(String platform) async {
    try {
      final jsonStr = await _storage.read(key: '$_storagePrefix$platform');
      if (jsonStr != null) {
        final data = json.decode(jsonStr) as Map<String, dynamic>;
        _tokens[platform] = AuthToken.fromJson(data);
      }
    } catch (e) {
      debugPrint('Failed to load token for $platform: $e');
    }
  }

  /// Save a token to secure storage.
  /// This can be called directly (e.g., after WebView cookie extraction)
  /// without going through the OAuth flow.
  Future<void> saveToken({
    required String platform,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) async {
    final token = AuthToken(
      platform: platform,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
    await _saveToken(token);
    notifyListeners();
  }

  /// Save a token to secure storage.
  Future<void> _saveToken(AuthToken token) async {
    await _storage.write(
      key: '$_storagePrefix${token.platform}',
      value: json.encode(token.toJson()),
    );
  }

  /// Convert OAuth errors to user-friendly messages.
  String _userFriendlyError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('cancelled') || msg.contains('user_cancelled')) {
      return 'Login was cancelled.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (msg.contains('invalid_grant') || msg.contains('unauthorized')) {
      return 'Authorization failed. Please try again.';
    }
    if (msg.contains('redirect') || msg.contains('redirect_uri')) {
      return 'Configuration error. Please contact support.';
    }
    return 'Authentication failed. Please try again.';
  }
}
