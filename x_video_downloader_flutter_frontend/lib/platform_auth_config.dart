/// OAuth2 configuration for each supported platform.
///
/// These configs use placeholder client IDs that must be replaced
/// with real credentials from each platform's developer portal:
///   - Twitter: https://developer.twitter.com
///   - Instagram: https://developers.facebook.com
///   - TikTok: https://developers.tiktok.com
class PlatformAuthConfig {
  final String platform;
  final String displayName;
  final String clientId;
  final String clientSecret;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String redirectUrl;
  final List<String> scopes;
  final String discoveryUrl;

  const PlatformAuthConfig({
    required this.platform,
    required this.displayName,
    required this.clientId,
    required this.clientSecret,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.redirectUrl,
    required this.scopes,
    required this.discoveryUrl,
  });

  /// Twitter/X OAuth2 config using Authorization Code flow with PKCE.
  static const twitter = PlatformAuthConfig(
    platform: 'twitter',
    displayName: 'X (Twitter)',
    clientId: 'YOUR_TWITTER_CLIENT_ID',
    clientSecret: '',
    redirectUrl: 'com.angriff.x_video_downloader://oauthredirect',
    scopes: ['tweet.read', 'users.read', 'offline.access'],
    authorizationEndpoint: 'https://twitter.com/i/oauth2/authorize',
    tokenEndpoint: 'https://api.twitter.com/2/oauth2/token',
    discoveryUrl: '',
  );

  /// Instagram OAuth2 config (uses Facebook Graph API).
  static const instagram = PlatformAuthConfig(
    platform: 'instagram',
    displayName: 'Instagram',
    clientId: 'YOUR_INSTAGRAM_APP_ID',
    clientSecret: 'YOUR_INSTAGRAM_APP_SECRET',
    redirectUrl: 'https://localhost/oauthredirect',
    scopes: ['instagram_basic', 'instagram_content_publish'],
    authorizationEndpoint: 'https://api.instagram.com/oauth/authorize',
    tokenEndpoint: 'https://api.instagram.com/oauth/access_token',
    discoveryUrl: '',
  );

  /// TikTok OAuth2 config.
  static const tiktok = PlatformAuthConfig(
    platform: 'tiktok',
    displayName: 'TikTok',
    clientId: 'YOUR_TIKTOK_CLIENT_KEY',
    clientSecret: 'YOUR_TIKTOK_CLIENT_SECRET',
    redirectUrl: 'com.angriff.x_video_downloader://oauthredirect',
    scopes: ['user.info.basic'],
    authorizationEndpoint: 'https://www.tiktok.com/v2/auth/authorize',
    tokenEndpoint: 'https://open.tiktokapis.com/v2/oauth/token/',
    discoveryUrl: '',
  );

  /// Get config for a platform by its name.
  static PlatformAuthConfig? forPlatform(String platformName) {
    switch (platformName.toLowerCase()) {
      case 'twitter':
      case 'x':
        return twitter;
      case 'instagram':
        return instagram;
      case 'tiktok':
        return tiktok;
      default:
        return null;
    }
  }

  /// All platform configs.
  static List<PlatformAuthConfig> get all => [twitter, instagram, tiktok];

  /// Whether this platform has real credentials configured (not placeholder).
  bool get isConfigured =>
      !clientId.startsWith('YOUR_') && clientId.isNotEmpty;
}
