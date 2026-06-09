import 'package:shared_preferences/shared_preferences.dart';

/// Manages custom filename templates for download file naming.
///
/// Templates use curly-brace placeholders that get resolved on the backend
/// using video metadata extracted by yt-dlp.
///
/// Supported placeholders:
///   {title}      - Video title (sanitized for filesystem)
///   {platform}   - Platform name (YouTube, Instagram, TikTok, etc.)
///   {uploader}   - Channel/uploader name
///   {date}       - Upload date as YYYY-MM-DD
///   {year}       - Upload year
///   {month}      - Upload month (zero-padded)
///   {day}        - Upload day (zero-padded)
///   {id}         - Video ID from the platform
///   {quality}    - Resolution/quality label (e.g. 1080p, 720p)
///   {ext}        - File extension (mp4, m4a, etc.)
///   {index}      - Index within a media group (1-based)
class FilenameTemplate {
  static const _prefsKey = 'filename_template';
  static const _perPlatformPrefsKey = 'filename_template_platform_';

  /// Default template — just the video title.
  static const defaultTemplate = '{title}';

  /// Predefined template presets users can choose from.
  static const presets = <TemplatePreset>[
    TemplatePreset(
      name: 'Title Only',
      template: '{title}',
      description: 'Just the video title',
    ),
    TemplatePreset(
      name: 'Platform - Title',
      template: '{platform} - {title}',
      description: 'Platform prefix for organized folders',
    ),
    TemplatePreset(
      name: 'Uploader - Title',
      template: '{uploader} - {title}',
      description: 'Organize by creator/channel',
    ),
    TemplatePreset(
      name: 'Date - Title',
      template: '{date} {title}',
      description: 'Sort by upload date',
    ),
    TemplatePreset(
      name: 'Full Metadata',
      template: '{platform} [{uploader}] {title} ({quality})',
      description: 'Maximum information in filename',
    ),
    TemplatePreset(
      name: 'Title (Quality)',
      template: '{title} ({quality})',
      description: 'Title with resolution tag',
    ),
  ];

  static SharedPreferences? _prefs;

  /// Initialize shared preferences (call once at startup).
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _prefsInstance {
    if (_prefs == null) {
      throw StateError('FilenameTemplate not initialized. Call init() first.');
    }
    return _prefs!;
  }

  /// Get the current global filename template.
  static String get current {
    return _prefsInstance.getString(_prefsKey) ?? defaultTemplate;
  }

  /// Set the global filename template.
  static Future<bool> set(String template) {
    return _prefsInstance.setString(_prefsKey, template);
  }

  /// Reset to the default template.
  static Future<bool> reset() {
    return _prefsInstance.remove(_prefsKey);
  }

  /// Get a per-platform template override.
  /// Returns null if no override is set for that platform.
  static String? getForPlatform(String platform) {
    final key = '$_perPlatformPrefsKey${platform.toLowerCase()}';
    return _prefsInstance.getString(key);
  }

  /// Set a per-platform template override.
  static Future<bool> setForPlatform(String platform, String template) {
    final key = '$_perPlatformPrefsKey${platform.toLowerCase()}';
    return _prefsInstance.setString(key, template);
  }

  /// Remove a per-platform template override.
  static Future<bool> removeForPlatform(String platform) {
    final key = '$_perPlatformPrefsKey${platform.toLowerCase()}';
    return _prefsInstance.remove(key);
  }

  /// Get the effective template for a given platform.
  /// Returns the platform-specific override if set, otherwise the global template.
  static String effectiveTemplate(String platform) {
    return getForPlatform(platform) ?? current;
  }

  /// List of all available placeholders with descriptions.
  static const placeholders = <PlaceholderInfo>[
    PlaceholderInfo(tag: 'title', description: 'Video title'),
    PlaceholderInfo(tag: 'platform', description: 'Platform name (YouTube, Instagram, etc.)'),
    PlaceholderInfo(tag: 'uploader', description: 'Channel/uploader name'),
    PlaceholderInfo(tag: 'date', description: 'Upload date (YYYY-MM-DD)'),
    PlaceholderInfo(tag: 'year', description: 'Upload year'),
    PlaceholderInfo(tag: 'month', description: 'Upload month'),
    PlaceholderInfo(tag: 'day', description: 'Upload day'),
    PlaceholderInfo(tag: 'id', description: 'Video ID'),
    PlaceholderInfo(tag: 'quality', description: 'Quality/resolution (1080p, 720p, etc.)'),
    PlaceholderInfo(tag: 'ext', description: 'File extension (mp4, m4a)'),
    PlaceholderInfo(tag: 'index', description: 'Index in media group'),
  ];

  /// Validate a template string. Returns null if valid, or an error message.
  static String? validate(String template) {
    if (template.trim().isEmpty) {
      return 'Template cannot be empty';
    }
    // Check for invalid characters that would break filenames
    if (template.contains(RegExp(r'[<>:"/\\|?*]'))) {
      return 'Template contains invalid filename characters';
    }
    return null; // Valid
  }

  /// Generate a preview filename from a template, using example data.
  static String preview(String template) {
    return template
        .replaceAll('{title}', 'Amazing Video Title')
        .replaceAll('{platform}', 'YouTube')
        .replaceAll('{uploader}', 'ChannelName')
        .replaceAll('{date}', '2025-01-15')
        .replaceAll('{year}', '2025')
        .replaceAll('{month}', '01')
        .replaceAll('{day}', '15')
        .replaceAll('{id}', 'dQw4w9WgXcQ')
        .replaceAll('{quality}', '1080p')
        .replaceAll('{ext}', 'mp4')
        .replaceAll('{index}', '1');
  }
}

/// A predefined template preset.
class TemplatePreset {
  final String name;
  final String template;
  final String description;

  const TemplatePreset({
    required this.name,
    required this.template,
    required this.description,
  });
}

/// Describes a single template placeholder.
class PlaceholderInfo {
  final String tag;
  final String description;

  const PlaceholderInfo({
    required this.tag,
    required this.description,
  });
}
