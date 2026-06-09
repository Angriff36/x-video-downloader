import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'platform_auth_config.dart';

/// Screen for managing platform authentication (login/logout).
///
/// Shows each supported platform with a login button or logged-in status.
class AuthSettingsScreen extends StatefulWidget {
  final AuthService authService;

  const AuthSettingsScreen({super.key, required this.authService});

  @override
  State<AuthSettingsScreen> createState() => _AuthSettingsScreenState();
}

class _AuthSettingsScreenState extends State<AuthSettingsScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleLogin(PlatformAuthConfig config) async {
    if (!config.isConfigured) {
      setState(() {
        _errorMessage =
            'OAuth credentials not configured. Add your ${config.displayName} '
            'client ID in platform_auth_config.dart to enable login.';
      });
      return;
    }

    setState(() => _errorMessage = null);
    final result = await widget.authService.login(config);

    if (!result.success && mounted) {
      setState(() => _errorMessage = result.error);
    }
  }

  Future<void> _handleLogout(String platform) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: Text(
            'Remove stored credentials for ${PlatformAuthConfig.forPlatform(platform)?.displayName ?? platform}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.authService.logout(platform);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Accounts'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Sign in to platforms for access to authenticated content.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Logged-in accounts can download age-restricted or private content you have access to.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ...PlatformAuthConfig.all.map((config) => _PlatformCard(
                config: config,
                token: widget.authService.tokenFor(config.platform),
                isLoading: widget.authService.isLoading(config.platform),
                isAuthenticated: widget.authService.isAuthenticated(config.platform),
                onLogin: () => _handleLogin(config),
                onLogout: () => _handleLogout(config.platform),
              )),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Note: OAuth credentials must be configured in the app to enable platform login. '
            'See platform_auth_config.dart for setup instructions.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

/// Card showing a single platform's authentication status and actions.
class _PlatformCard extends StatelessWidget {
  final PlatformAuthConfig config;
  final AuthToken? token;
  final bool isLoading;
  final bool isAuthenticated;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const _PlatformCard({
    required this.config,
    this.token,
    required this.isLoading,
    required this.isAuthenticated,
    required this.onLogin,
    required this.onLogout,
  });

  IconData get _platformIcon {
    switch (config.platform) {
      case 'twitter':
        return Icons.close; // Closest to X logo in Material
      case 'instagram':
        return Icons.camera_alt;
      case 'tiktok':
        return Icons.music_note;
      default:
        return Icons.link;
    }
  }

  Color get _platformColor {
    switch (config.platform) {
      case 'twitter':
        return Colors.black;
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'tiktok':
        return const Color(0xFF010101);
      default:
        return Colors.blue;
    }
  }

  String get _statusText {
    if (isAuthenticated) return 'Connected';
    if (token != null && token!.isExpired) return 'Expired - tap to reconnect';
    if (!config.isConfigured) return 'Not configured';
    return 'Not connected';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _platformColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_platformIcon, color: _platformColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAuthenticated
                              ? Colors.green
                              : token?.isExpired == true
                                  ? Colors.orange
                                  : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isAuthenticated
                              ? Colors.green
                              : token?.isExpired == true
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isAuthenticated)
              TextButton(
                onPressed: onLogout,
                child: const Text('Log Out'),
              )
            else
              ElevatedButton(
                onPressed: config.isConfigured ? onLogin : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _platformColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Log In'),
              ),
          ],
        ),
      ),
    );
  }
}
