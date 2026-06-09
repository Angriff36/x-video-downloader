import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:path_provider/path_provider.dart';
import 'download_record.dart';
import 'download_database.dart';
import 'download_history_screen.dart';
import 'download_queue_manager.dart';
import 'download_queue_screen.dart';
import 'queue_item.dart';
import 'format_option.dart';
import 'subtitle_option.dart';
import 'download_scheduler.dart';
import 'download_schedule_screen.dart';
import 'auth_service.dart';
import 'auth_settings_screen.dart';
import 'network_monitor.dart';
import 'batch_import_screen.dart';
import 'theme_provider.dart';
import 'app_theme.dart';
import 'theme_settings_screen.dart';
import 'filename_template.dart';
import 'filename_template_settings_screen.dart';
import 'download_analytics_screen.dart';
import 'storage_management_screen.dart';
import 'storage_service.dart';
import 'dart:async';

/// Regex to detect supported video platform URLs in clipboard text.
final _videoUrlPattern = RegExp(
  r'(https?://(?:'
  r'(?:www\.)?(?:x\.com|twitter\.com)/\w+/status/\d+' // X/Twitter
  r'|(?:www\.)?(?:youtube\.com/(?:watch\?v=|shorts/|embed/)|youtu\.be/)' // YouTube
  r'|(?:www\.)?(?:instagram\.com/(?:reel|p|tv)/)' // Instagram
  r'|(?:www\.)?(?:tiktok\.com/@[^/]+/video/)' // TikTok
  r'|(?:www\.)?(?:facebook\.com/(?:watch|reel|videos/))' // Facebook
  r'|(?:www\.)?(?:vimeo\.com/\d+)' // Vimeo
  r'|(?:www\.)?(?:reddit\.com/r/[^/]+/comments/)' // Reddit
  r'|(?:www\.)?(?:dailymotion\.com/video/)' // Dailymotion
  r')[^\s<>"{}|\\^`\[\]]*)',
  caseSensitive: false,
);

/// Extracts the first video URL from text, or returns null.
String? _extractVideoUrl(String text) {
  final match = _videoUrlPattern.firstMatch(text);
  return match?.group(0);
}

// --- Backend configuration ---
const String _backendBaseUrl = String.fromEnvironment(
  'BACKEND_BASE_URL',
  defaultValue: 'https://x-video-downloader-backend.fly.dev',
);

const MethodChannel _mediaChannel = MethodChannel(
  'com.angriff.x_video_downloader/media_scanner',
);

// --- Global queue manager ---
final DownloadQueueManager _queueManager = DownloadQueueManager();

// --- Global auth service ---
final AuthService _authService = AuthService();

// --- Global network monitor ---
final NetworkMonitor _networkMonitor = NetworkMonitor();

// --- Global theme provider ---
final ThemeProvider _themeProvider = ThemeProvider();

// --- Global download scheduler ---
final DownloadScheduler _scheduler = DownloadScheduler();

// --- Global storage service ---
final StorageService _storageService = StorageService();

// --- Error handling ---

/// Parsed error from the backend API.
class ApiError {
  final String message;
  final String errorCode;
  final bool retryable;

  const ApiError({
    required this.message,
    required this.errorCode,
    this.retryable = false,
  });

  /// Parse a structured error from the backend response body.
  /// Falls back to raw body if the response is not in expected format.
  static ApiError fromResponseBody(String body, {int statusCode = 500}) {
    try {
      final data = json.decode(body) as Map<String, dynamic>;
      final detail = data['detail'];
      return ApiError(
        message:
            data['error'] as String? ??
            (detail is String ? detail : null) ??
            'Request failed (HTTP $statusCode)',
        errorCode: data['error_code'] as String? ?? 'http_$statusCode',
        retryable: data['retryable'] as bool? ?? false,
      );
    } catch (_) {
      // Non-JSON or unexpected format — classify by status code
      if (statusCode >= 500) {
        return const ApiError(
          message: 'Server error. Please try again later.',
          errorCode: 'server_error',
          retryable: true,
        );
      }
      if (statusCode == 429) {
        return const ApiError(
          message: 'Too many requests. Please wait a moment and try again.',
          errorCode: 'rate_limited',
          retryable: true,
        );
      }
      if (statusCode == 404) {
        return const ApiError(
          message: 'Video not found or no longer available.',
          errorCode: 'not_found',
          retryable: false,
        );
      }
      return ApiError(
        message: body.isNotEmpty ? body : 'Request failed (HTTP $statusCode)',
        errorCode: 'http_$statusCode',
        retryable: false,
      );
    }
  }

  /// Classify a client-side exception (network, timeout, etc.).
  static ApiError fromException(Object e) {
    final msg = e.toString().toLowerCase();
    if (e is SocketException || msg.contains('connection')) {
      return const ApiError(
        message:
            'No internet connection. Please check your network and try again.',
        errorCode: 'network_error',
        retryable: true,
      );
    }
    if (e is TimeoutException ||
        msg.contains('timeout') ||
        msg.contains('timed out')) {
      return const ApiError(
        message:
            'Request timed out. Please check your connection and try again.',
        errorCode: 'timeout',
        retryable: true,
      );
    }
    if (e is FormatException || msg.contains('format')) {
      return const ApiError(
        message: 'Received an invalid response from the server.',
        errorCode: 'parse_error',
        retryable: true,
      );
    }
    if (e is HandshakeException ||
        msg.contains('ssl') ||
        msg.contains('certificate')) {
      return const ApiError(
        message: 'Secure connection failed. Please try again.',
        errorCode: 'ssl_error',
        retryable: true,
      );
    }
    return ApiError(
      message: 'An unexpected error occurred: $e',
      errorCode: 'unknown',
      retryable: false,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _authService.init();
  await _networkMonitor.init();
  await _themeProvider.init();
  await FilenameTemplate.init();
  _queueManager.authService = _authService;
  _queueManager.networkMonitor = _networkMonitor;
  await _queueManager.init();
  _scheduler.queueManager = _queueManager;
  _scheduler.networkMonitor = _networkMonitor;
  await _scheduler.init();
  // Run auto-cleanup in background (doesn't block startup)
  _storageService.runAutoCleanup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeProvider,
      builder: (context, _) {
        return MaterialApp(
          theme: AppTheme.light(_themeProvider.accent),
          darkTheme: AppTheme.dark(_themeProvider.accent),
          themeMode: _themeProvider.mode,
          home: const DownloaderScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

/// Data model for a single video in a media group.
class VideoItem {
  final int index;
  final String title;
  final String url;
  final dynamic duration;
  final String? thumbnail;
  final String id;

  VideoItem({
    required this.index,
    required this.title,
    required this.url,
    this.duration,
    this.thumbnail,
    required this.id,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      index: json['index'] as int,
      title: json['title'] as String? ?? 'Video',
      url: json['url'] as String? ?? '',
      duration: json['duration'],
      thumbnail: json['thumbnail'] as String?,
      id: json['id'] as String? ?? '',
    );
  }

  String get durationText {
    if (duration == null) return '';
    final d = Duration(seconds: (duration as num).toInt());
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }
}

/// Result of probing a URL.
class ProbeResult {
  final bool isGroup;
  final String groupTitle;
  final int count;
  final List<VideoItem> videos;

  ProbeResult({
    required this.isGroup,
    required this.groupTitle,
    required this.count,
    required this.videos,
  });

  factory ProbeResult.fromJson(Map<String, dynamic> json) {
    final videoList =
        (json['videos'] as List)
            .map((v) => VideoItem.fromJson(v as Map<String, dynamic>))
            .toList();
    return ProbeResult(
      isGroup: json['is_group'] as bool,
      groupTitle: json['group_title'] as String? ?? '',
      count: json['count'] as int,
      videos: videoList,
    );
  }
}

class DownloaderScreen extends StatefulWidget {
  const DownloaderScreen({super.key});

  @override
  State<DownloaderScreen> createState() => _DownloaderScreenState();
}

class _DownloaderScreenState extends State<DownloaderScreen>
    with ClipboardListener {
  final TextEditingController _urlController = TextEditingController();
  String status = "";
  bool _isProbing = false;
  bool _isDirectDownloading = false;
  double? _directDownloadProgress;

  // Media group state
  final Set<int> _selectedIndices = {};

  // Clipboard detection state
  String? _lastClipboardUrl;
  bool _clipboardSheetVisible = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      _listenForSharedText();
    }
    // Start clipboard watching
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();

    // Listen to queue changes to update status
    _queueManager.addListener(_onQueueUpdate);
  }

  @override
  void dispose() {
    _queueManager.removeListener(_onQueueUpdate);
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
    _urlController.dispose();
    super.dispose();
  }

  void _onQueueUpdate() {
    if (!mounted) return;
    final activeCount = _queueManager.activeCount;
    final pendingCount = _queueManager.pendingCount;
    if (activeCount > 0 || pendingCount > 0) {
      setState(() {
        status = "Downloading: $activeCount active, $pendingCount queued";
      });
    }
  }

  @override
  void onClipboardChanged() async {
    if (_clipboardSheetVisible) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    final url = _extractVideoUrl(data!.text!);
    if (url == null || url == _lastClipboardUrl) return;
    if (url == _urlController.text.trim()) return;
    _lastClipboardUrl = url;
    _showClipboardUrlSheet(url);
  }

  void _showClipboardUrlSheet(String url) {
    setState(() => _clipboardSheetVisible = true);
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video URL detected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Dismiss'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _urlController.text = url;
                              status = 'URL loaded from clipboard';
                            });
                            _probeUrl();
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Download'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    ).whenComplete(() {
      setState(() => _clipboardSheetVisible = false);
    });
  }

  void _listenForSharedText() {
    ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          final sharedText = value.first.path;
          _handleSharedText(sharedText);
        }
      },
      onError: (err) {
        debugPrint("Sharing Error: $err");
      },
    );

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        final sharedText = value.first.path;
        _handleSharedText(sharedText);
      }
    });
  }

  /// Handle text shared from another app, detecting single or multiple URLs.
  void _handleSharedText(String text) {
    final urls =
        _videoUrlPattern.allMatches(text).map((m) => m.group(0)!).toList();

    if (urls.isEmpty) {
      // Not a recognized video URL — set as-is
      setState(() {
        _urlController.text = text;
        status = "Link received via Share";
      });
    } else if (urls.length == 1) {
      // Single URL — set and auto-probe
      setState(() {
        _urlController.text = urls.first;
        status = "Link received via Share";
      });
      _probeUrl();
    } else {
      // Multiple URLs — open batch import
      Navigator.push<int>(
        context,
        MaterialPageRoute(
          builder:
              (_) => BatchImportScreen(
                queueManager: _queueManager,
                initialText: text,
              ),
        ),
      ).then((count) {
        if (count != null && count > 0) {
          setState(() {
            status = "Added $count URLs to download queue";
          });
        }
      });
    }
  }

  /// Probe the URL to detect media groups.
  Future<void> _probeUrl({bool chooseQuality = false}) async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Client-side URL validation
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        status = "Please enter a valid URL starting with http:// or https://";
        _isProbing = false;
      });
      return;
    }

    setState(() {
      _isProbing = true;
      status = "Detecting media...";
      _selectedIndices.clear();
    });

    final endpoint = "$_backendBaseUrl/probe?url=${Uri.encodeComponent(url)}";

    try {
      final response = await http
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('error')) {
          final apiError = ApiError.fromResponseBody(
            response.body,
            statusCode: response.statusCode,
          );
          setState(() {
            status = apiError.message;
            _isProbing = false;
          });
          return;
        }

        final result = ProbeResult.fromJson(data);
        setState(() {
          _isProbing = false;
        });

        if (result.isGroup && result.videos.length > 1) {
          // Select all by default
          _selectedIndices.addAll(result.videos.map((v) => v.index));
          _showMediaGroupSheet(result);
        } else {
          // Single video: the primary Download action should start immediately.
          final title = result.videos.first.title;
          final thumbnailUrl = result.videos.first.thumbnail;
          if (chooseQuality) {
            _fetchFormatsAndShowPicker(
              url: url,
              title: title,
              thumbnailUrl: thumbnailUrl,
            );
          } else {
            await _downloadDirectly(
              url: url,
              title: title,
              thumbnailUrl: thumbnailUrl,
            );
          }
        }
      } else {
        final apiError = ApiError.fromResponseBody(
          response.body,
          statusCode: response.statusCode,
        );
        setState(() {
          status = apiError.message;
          _isProbing = false;
        });
      }
    } catch (e) {
      final apiError = ApiError.fromException(e);
      setState(() {
        status = apiError.message;
        _isProbing = false;
      });
    }
  }

  /// Fetch available formats for a video and show quality picker.
  Future<void> _fetchFormatsAndShowPicker({
    required String url,
    required String title,
    String? thumbnailUrl,
  }) async {
    setState(() {
      status = "Loading available qualities...";
    });

    final endpoint = "$_backendBaseUrl/formats?url=${Uri.encodeComponent(url)}";

    try {
      final response = await http
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('error')) {
          // Format listing failed — fall back to best quality
          setState(() {
            status = "Added to queue: $title (best quality)";
          });
          _queueManager.addToQueue(
            url: url,
            title: title,
            thumbnailUrl: thumbnailUrl,
          );
          return;
        }

        final formatsResult = FormatsResult.fromJson(data);
        setState(() {
          status = "";
        });

        _showQualityPickerSheet(
          url: url,
          title: title,
          thumbnailUrl: thumbnailUrl,
          formatsResult: formatsResult,
        );
      } else {
        // Fall back to best quality on error
        setState(() {
          status = "Added to queue: $title (best quality)";
        });
        _queueManager.addToQueue(
          url: url,
          title: title,
          thumbnailUrl: thumbnailUrl,
        );
      }
    } catch (e) {
      // Fall back to best quality on error
      setState(() {
        status = "Added to queue: $title (best quality)";
      });
      _queueManager.addToQueue(
        url: url,
        title: title,
        thumbnailUrl: thumbnailUrl,
      );
    }
  }

  /// Show bottom sheet for quality/format selection.
  void _showQualityPickerSheet({
    required String url,
    required String title,
    String? thumbnailUrl,
    required FormatsResult formatsResult,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => _QualityPickerSheet(
            title: title,
            thumbnailUrl: thumbnailUrl,
            videoUrl: url,
            formats: formatsResult.formats,
            onFormatSelected: (
              formatOption,
              subtitleLang,
              subtitleFormat,
              embedSubs,
              sidecarSubs,
            ) {
              Navigator.pop(context);
              final label =
                  formatOption.isAudioOnly
                      ? 'Audio (${formatOption.ext.toUpperCase()})'
                      : formatOption.resolution;
              final subInfo = subtitleLang != null ? ' + subs' : '';
              setState(() {
                status = "Added to queue: $title ($label$subInfo)";
              });
              _queueManager.addToQueue(
                url: url,
                title: title,
                thumbnailUrl: thumbnailUrl,
                formatId: formatOption.ytFormat,
                formatLabel: label,
                subtitleLang: subtitleLang,
                subtitleFormat: subtitleFormat,
                embedSubtitles: embedSubs,
                downloadSidecarSubtitles: sidecarSubs,
              );
            },
            onBestQualitySelected: (
              subtitleLang,
              subtitleFormat,
              embedSubs,
              sidecarSubs,
            ) {
              Navigator.pop(context);
              final subInfo = subtitleLang != null ? ' + subs' : '';
              setState(() {
                status = "Added to queue: $title (best quality$subInfo)";
              });
              _queueManager.addToQueue(
                url: url,
                title: title,
                thumbnailUrl: thumbnailUrl,
                subtitleLang: subtitleLang,
                subtitleFormat: subtitleFormat,
                embedSubtitles: embedSubs,
                downloadSidecarSubtitles: sidecarSubs,
              );
            },
          ),
    );
  }

  /// Show bottom sheet for media group selection.
  void _showMediaGroupSheet(ProbeResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => _MediaGroupSheet(
            result: result,
            selectedIndices: _selectedIndices,
            onToggle: (index) {
              setState(() {
                if (_selectedIndices.contains(index)) {
                  _selectedIndices.remove(index);
                } else {
                  _selectedIndices.add(index);
                }
              });
            },
            onSelectAll: () {
              setState(() {
                _selectedIndices.addAll(result.videos.map((v) => v.index));
              });
            },
            onDeselectAll: () {
              setState(() {
                _selectedIndices.clear();
              });
            },
            onDownload: () {
              Navigator.pop(context);
              _addToQueueFromGroup(result);
            },
          ),
    );
  }

  /// Add selected videos from a media group to the download queue.
  Future<void> _addToQueueFromGroup(ProbeResult result) async {
    final url = _urlController.text.trim();
    final selectedVideos =
        result.videos.where((v) => _selectedIndices.contains(v.index)).toList();

    if (selectedVideos.isEmpty) {
      setState(() => status = "No videos selected");
      return;
    }

    final items =
        selectedVideos
            .map(
              (v) => QueueItem(
                url: url,
                platform: DownloadRecord.detectPlatform(url),
                title: v.title,
                thumbnailUrl: v.thumbnail,
                videoIndex: v.index,
                createdAt: DateTime.now(),
              ),
            )
            .toList();

    await _queueManager.addBatchToQueue(items);

    setState(() {
      status = "Added ${items.length} videos to download queue";
    });
  }

  Future<void> _downloadCurrentUrlDirectly() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        status = "Please enter a valid URL starting with http:// or https://";
      });
      return;
    }

    await _downloadDirectly(url: url, title: _fallbackTitleFromUrl(url));
  }

  Future<void> _persistDirectDownloadHistory({
    required String url,
    required String title,
    required String filePath,
    required int fileSizeBytes,
    required bool success,
    String? errorMessage,
    String? thumbnailUrl,
  }) async {
    try {
      await DownloadDatabase().insertRecord(
        DownloadRecord(
          url: url,
          platform: DownloadRecord.detectPlatform(url),
          title: title,
          filePath: filePath,
          fileSizeBytes: fileSizeBytes,
          status: success ? 'completed' : 'failed',
          errorMessage: errorMessage,
          downloadedAt: DateTime.now(),
          thumbnailUrl: thumbnailUrl,
        ),
      );
    } catch (e, st) {
      debugPrint('Failed to persist direct download history: $e $st');
    }
  }

  /// Same folder layout as [DownloadQueueManager] so files survive cache clears.
  Future<String> _appVideoDownloadDir() async {
    Directory baseDir;
    if (Platform.isAndroid) {
      baseDir =
          (await getExternalStorageDirectory()) ??
          await getApplicationDocumentsDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final dir = Directory('${baseDir.path}/x_video_downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<void> _downloadDirectly({
    required String url,
    required String title,
    String? thumbnailUrl,
  }) async {
    setState(() {
      _isDirectDownloading = true;
      _directDownloadProgress = null;
      status = "Starting download...";
    });

    final template = FilenameTemplate.effectiveTemplate(
      DownloadRecord.detectPlatform(url),
    );
    final endpoint =
        "$_backendBaseUrl/download?url=${Uri.encodeComponent(url)}&filename_template=${Uri.encodeComponent(template)}";
    final client = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(endpoint));
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 180));

      if (response.statusCode != 200 && response.statusCode != 206) {
        final body = await response.stream.bytesToString();
        final apiError = ApiError.fromResponseBody(
          body,
          statusCode: response.statusCode,
        );
        setState(() {
          status = apiError.message;
          _isDirectDownloading = false;
          _directDownloadProgress = null;
        });
        return;
      }

      final contentType = response.headers['content-type'];
      if (contentType != null && contentType.contains('application/json')) {
        final body = await response.stream.bytesToString();
        final apiError = ApiError.fromResponseBody(
          body,
          statusCode: response.statusCode,
        );
        setState(() {
          status = apiError.message;
          _isDirectDownloading = false;
          _directDownloadProgress = null;
        });
        return;
      }

      final saveDir = await _appVideoDownloadDir();
      final extension = _extensionFromContentType(contentType);
      final headerName = _filenameFromContentDisposition(
        response.headers['content-disposition'],
      );
      final displayName =
          headerName ??
          "${_sanitizeLocalFilename(title)}_${DateTime.now().millisecondsSinceEpoch}.$extension";
      final file = File("$saveDir/$displayName");
      final sink = file.openWrite();
      final expectedBytes = response.contentLength;
      var receivedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (expectedBytes != null && expectedBytes > 0 && mounted) {
          setState(() {
            _directDownloadProgress = receivedBytes / expectedBytes;
            status =
                "Downloading ${(_directDownloadProgress! * 100).toStringAsFixed(0)}%";
          });
        }
      }
      await sink.close();

      await _publishToDownloads(file.path, displayName, extension);

      await _persistDirectDownloadHistory(
        url: url,
        title: title,
        filePath: file.path,
        fileSizeBytes: receivedBytes,
        success: true,
        thumbnailUrl: thumbnailUrl,
      );

      if (!mounted) return;
      setState(() {
        status = "Downloaded to Downloads/x_video_downloads";
        _isDirectDownloading = false;
        _directDownloadProgress = 1.0;
      });
    } catch (e) {
      final apiError = ApiError.fromException(e);
      if (!mounted) return;
      setState(() {
        status = apiError.message;
        _isDirectDownloading = false;
        _directDownloadProgress = null;
      });
    } finally {
      client.close();
    }
  }

  Future<void> _publishToDownloads(
    String filePath,
    String displayName,
    String extension,
  ) async {
    if (!Platform.isAndroid) return;
    final mimeType = extension == 'mp3' ? 'audio/mpeg' : 'video/mp4';
    await _mediaChannel.invokeMethod('publishToDownloads', {
      'path': filePath,
      'displayName': displayName,
      'mimeType': mimeType,
    });
  }

  String _sanitizeLocalFilename(String name) {
    var safe = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '');
    safe = safe.replaceAll(RegExp(r'\s+'), ' ').trim();
    while (safe.endsWith('.') || safe.endsWith(' ')) {
      safe = safe.substring(0, safe.length - 1);
    }
    while (safe.startsWith('.') || safe.startsWith(' ')) {
      safe = safe.substring(1);
    }
    if (safe.length > 80) {
      safe = safe.substring(0, 80);
    }
    return safe.isEmpty ? 'video' : safe;
  }

  String _extensionFromContentType(String? contentType) {
    final lower = contentType?.toLowerCase() ?? '';
    if (lower.contains('audio')) return 'mp3';
    if (lower.contains('webm')) return 'webm';
    return 'mp4';
  }

  String _fallbackTitleFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final lastSegment =
        uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : null;
    if (lastSegment != null && lastSegment.isNotEmpty) {
      return 'video_$lastSegment';
    }
    return 'video';
  }

  String? _filenameFromContentDisposition(String? header) {
    if (header == null || header.isEmpty) return null;

    final encodedMatch = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(header);
    final encodedName = encodedMatch?.group(1);
    if (encodedName != null && encodedName.isNotEmpty) {
      return _sanitizeLocalFilename(Uri.decodeComponent(encodedName));
    }

    final plainMatch = RegExp(
      r'filename="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(header);
    final plainName = plainMatch?.group(1);
    if (plainName != null && plainName.isNotEmpty) {
      return _sanitizeLocalFilename(plainName);
    }

    return null;
  }

  Future<void> _launchDonationPage() async {
    final Uri url = Uri.parse('https://buymeacoffee.com/angriff');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveQueue =
        _queueManager.activeCount > 0 || _queueManager.pendingCount > 0;
    final visibleQueueItems =
        _queueManager.queue
            .where(
              (item) =>
                  item.status == QueueItemStatus.downloading ||
                  item.status == QueueItemStatus.queued,
            )
            .toList();
    final currentQueueItem =
        visibleQueueItems.isNotEmpty ? visibleQueueItems.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("X Video Downloader"),
        actions: [
          // Queue button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.queue),
                tooltip: 'Download Queue',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => DownloadQueueScreen(
                            queueManager: _queueManager,
                            networkMonitor: _networkMonitor,
                          ),
                    ),
                  );
                },
              ),
              if (hasActiveQueue)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '${_queueManager.activeCount + _queueManager.pendingCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Download History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DownloadHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DownloadAnalyticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: 'Scheduled Downloads',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => DownloadScheduleScreen(
                        scheduler: _scheduler,
                        networkMonitor: _networkMonitor,
                      ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Platform Accounts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AuthSettingsScreen(authService: _authService),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.palette),
            tooltip: 'Appearance',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ThemeSettingsScreen(themeProvider: _themeProvider),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Filename Templates',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FilenameTemplateSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.storage),
            tooltip: 'Storage Management',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StorageManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: "Paste Video URL",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.playlist_add, size: 22),
                  tooltip: 'Batch Import',
                  onPressed: () async {
                    final count = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                BatchImportScreen(queueManager: _queueManager),
                      ),
                    );
                    if (count != null && count > 0) {
                      setState(() {
                        status = "Added $count URLs to download queue";
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final intent = AndroidIntent(
                  action: 'android.intent.action.VIEW',
                  data: Uri.encodeFull('content://media/internal/video/media'),
                  flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
                );
                await intent.launch();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Open Gallery'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  (_isProbing || _isDirectDownloading)
                      ? null
                      : _downloadCurrentUrlDirectly,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child:
                  _isProbing
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text("Download"),
            ),
            if (_isDirectDownloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _directDownloadProgress),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed:
                  (_isProbing || _isDirectDownloading)
                      ? null
                      : () => _probeUrl(chooseQuality: true),
              icon: const Icon(Icons.tune),
              label: const Text("Choose Quality"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            // Queue status indicator
            if (hasActiveQueue)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => DownloadQueueScreen(
                            queueManager: _queueManager,
                            networkMonitor: _networkMonitor,
                          ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            currentQueueItem?.status ==
                                    QueueItemStatus.downloading
                                ? CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value:
                                      currentQueueItem!.progress > 0
                                          ? currentQueueItem.progress
                                          : null,
                                )
                                : const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_queueManager.activeCount} downloading, ${_queueManager.pendingCount} queued',
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (currentQueueItem != null) ...[
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value:
                                    currentQueueItem.status ==
                                                QueueItemStatus.downloading &&
                                            currentQueueItem.progress > 0
                                        ? currentQueueItem.progress
                                        : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => DownloadQueueScreen(
                            queueManager: _queueManager,
                            networkMonitor: _networkMonitor,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.queue),
                label: const Text("View Queue"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DownloadHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text("Download History"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => DownloadScheduleScreen(
                          scheduler: _scheduler,
                          networkMonitor: _networkMonitor,
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.schedule),
              label: const Text("Scheduled Downloads"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _launchDonationPage,
              icon: const Icon(Icons.coffee),
              label: const Text("Buy Me a Coffee"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            Text(status),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for selecting videos from a media group.
class _MediaGroupSheet extends StatelessWidget {
  final ProbeResult result;
  final Set<int> selectedIndices;
  final ValueChanged<int> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onDownload;

  const _MediaGroupSheet({
    required this.result,
    required this.selectedIndices,
    required this.onToggle,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.groupTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${result.count} videos found',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          onSelectAll();
                          setSheetState(() {});
                        },
                        child: const Text('All'),
                      ),
                      TextButton(
                        onPressed: () {
                          onDeselectAll();
                          setSheetState(() {});
                        },
                        child: const Text('None'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Video list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: result.videos.length,
                    itemBuilder: (context, i) {
                      final video = result.videos[i];
                      final isSelected = selectedIndices.contains(video.index);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) {
                          onToggle(video.index);
                          setSheetState(() {});
                        },
                        title: Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle:
                            video.durationText.isNotEmpty
                                ? Text(video.durationText)
                                : null,
                        secondary:
                            video.thumbnail != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    video.thumbnail!,
                                    width: 60,
                                    height: 45,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(
                                          Icons.videocam,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                  ),
                                )
                                : const Icon(
                                  Icons.videocam,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                      );
                    },
                  ),
                ),
                // Download button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: selectedIndices.isEmpty ? null : onDownload,
                        icon: const Icon(Icons.download),
                        label: Text(
                          'Download ${selectedIndices.length} Video${selectedIndices.length != 1 ? 's' : ''}',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Bottom sheet for selecting video quality/format with subtitle options.
class _QualityPickerSheet extends StatefulWidget {
  final String title;
  final String? thumbnailUrl;
  final String videoUrl;
  final List<FormatOption> formats;
  final void Function(
    FormatOption,
    String? subtitleLang,
    String? subtitleFormat,
    bool embedSubs,
    bool sidecarSubs,
  )
  onFormatSelected;
  final void Function(
    String? subtitleLang,
    String? subtitleFormat,
    bool embedSubs,
    bool sidecarSubs,
  )
  onBestQualitySelected;

  const _QualityPickerSheet({
    required this.title,
    this.thumbnailUrl,
    required this.videoUrl,
    required this.formats,
    required this.onFormatSelected,
    required this.onBestQualitySelected,
  });

  @override
  State<_QualityPickerSheet> createState() => _QualityPickerSheetState();
}

class _QualityPickerSheetState extends State<_QualityPickerSheet> {
  List<SubtitleOption> _subtitles = [];
  bool _subtitlesLoading = false;
  SubtitleOption? _selectedSubtitle;
  SubtitleFormat _subtitleFormat = SubtitleFormat.srt;
  SubtitleMode _subtitleMode = SubtitleMode.embed;

  @override
  void initState() {
    super.initState();
    _fetchSubtitles();
  }

  Future<void> _fetchSubtitles() async {
    setState(() => _subtitlesLoading = true);
    try {
      final endpoint =
          "$_backendBaseUrl/subtitles?url=${Uri.encodeComponent(widget.videoUrl)}";
      final response = await http
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('subtitles')) {
          final result = SubtitlesResult.fromJson(data);
          setState(() {
            _subtitles = result.uniqueByLanguage;
            // Auto-select English if available
            _selectedSubtitle =
                _subtitles.where((s) => s.language == 'en').firstOrNull ??
                (_subtitles.isNotEmpty ? _subtitles.first : null);
          });
        }
      }
    } catch (_) {
      // Non-fatal: subtitles are optional
    } finally {
      setState(() => _subtitlesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Separate formats into categories
    final combinedFormats =
        widget.formats.where((f) => f.formatType == 'video+audio').toList();
    final videoOnlyFormats =
        widget.formats.where((f) => f.formatType == 'video').toList();
    final audioOnlyFormats =
        widget.formats.where((f) => f.formatType == 'audio').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Select quality',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Format list
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  // Best quality option (default)
                  ListTile(
                    leading: const Icon(
                      Icons.auto_awesome,
                      color: Colors.green,
                    ),
                    title: const Text(
                      'Best Quality',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Auto-select best video+audio'),
                    onTap:
                        () => widget.onBestQualitySelected(
                          _selectedSubtitle?.language,
                          _subtitleFormat.extension,
                          _subtitleMode == SubtitleMode.embed &&
                              _selectedSubtitle != null,
                          _subtitleMode == SubtitleMode.sidecar &&
                              _selectedSubtitle != null,
                        ),
                  ),
                  const Divider(height: 1),

                  if (combinedFormats.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Video + Audio',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...combinedFormats.map((f) => _buildFormatTile(context, f)),
                  ],

                  if (videoOnlyFormats.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Video Only',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...videoOnlyFormats.map(
                      (f) => _buildFormatTile(context, f),
                    ),
                  ],

                  if (audioOnlyFormats.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Audio Only',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...audioOnlyFormats.map(
                      (f) => _buildFormatTile(context, f),
                    ),
                  ],

                  // Subtitle section
                  if (_subtitlesLoading || _subtitles.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Icon(Icons.subtitles, size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(
                            'Subtitles',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_subtitlesLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    if (_subtitles.isNotEmpty) ...[
                      _buildSubtitleLanguagePicker(),
                      if (_selectedSubtitle != null) ...[
                        _buildSubtitleFormatPicker(),
                        _buildSubtitleModePicker(),
                      ],
                    ],
                  ],

                  const SizedBox(height: 80), // Bottom padding for safe area
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubtitleLanguagePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<SubtitleOption>(
        initialValue: _selectedSubtitle,
        decoration: const InputDecoration(
          labelText: 'Language',
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          const DropdownMenuItem<SubtitleOption>(
            value: null,
            child: Text('None'),
          ),
          ..._subtitles.map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(
                '${s.languageCode} - ${s.displayLabel}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() => _selectedSubtitle = value);
        },
      ),
    );
  }

  Widget _buildSubtitleFormatPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children:
            SubtitleFormat.values.map((fmt) {
              final selected = fmt == _subtitleFormat;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    label: Text(fmt.displayName),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _subtitleFormat = fmt);
                    },
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSubtitleModePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children:
            SubtitleMode.values.map((mode) {
              final selected = mode == _subtitleMode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    avatar: Icon(
                      mode == SubtitleMode.embed
                          ? Icons.merge
                          : Icons.call_split,
                      size: 16,
                    ),
                    label: Text(mode.displayName),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _subtitleMode = mode);
                    },
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildFormatTile(BuildContext context, FormatOption format) {
    return ListTile(
      leading: Icon(
        format.isAudioOnly ? Icons.audiotrack : Icons.videocam,
        color:
            format.isAudioOnly
                ? Colors.orange
                : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        format.qualityLabel,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        format.shortDescription,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      trailing:
          format.filesizeText.isNotEmpty
              ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  format.filesizeText,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
              : null,
      onTap:
          () => widget.onFormatSelected(
            format,
            _selectedSubtitle?.language,
            _subtitleFormat.extension,
            _subtitleMode == SubtitleMode.embed && _selectedSubtitle != null,
            _subtitleMode == SubtitleMode.sidecar && _selectedSubtitle != null,
          ),
    );
  }
}
