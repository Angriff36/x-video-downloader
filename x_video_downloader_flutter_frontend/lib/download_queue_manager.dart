import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'auth_service.dart';
import 'download_database.dart';
import 'download_record.dart';
import 'filename_template.dart';
import 'network_monitor.dart';
import 'queue_item.dart';

const String _backendBaseUrl = String.fromEnvironment(
  'BACKEND_BASE_URL',
  defaultValue: 'https://x-video-downloader-backend.fly.dev',
);

const MethodChannel _mediaChannel = MethodChannel(
  'com.angriff.x_video_downloader/media_scanner',
);

/// Callback type for queue change notifications.
typedef QueueChangeCallback = void Function();

/// Manages the download queue with concurrent downloads, pause/resume,
/// automatic retry, and progress persistence.
class DownloadQueueManager extends ChangeNotifier {
  final DownloadDatabase _db = DownloadDatabase();

  /// Auth service for platform tokens. Set during app initialization.
  AuthService? authService;

  /// Network monitor for WiFi-only mode.
  NetworkMonitor? networkMonitor;

  /// IDs of items paused by WiFi disconnect (not user-initiated).
  final Set<int> _wifiPausedItems = {};

  /// Active queue items (in-memory for fast UI updates).
  final List<QueueItem> _queue = [];

  /// Currently active downloads (downloading or paused).
  final Map<int, _ActiveDownload> _activeDownloads = {};

  /// Maximum number of concurrent downloads.
  int _maxConcurrent = 2;

  /// Whether the queue is globally paused.
  bool _isGloballyPaused = false;

  /// Whether the manager has been initialized.
  bool _initialized = false;

  /// Stream controllers for per-item progress updates.
  final Map<int, StreamController<QueueItem>> _itemControllers = {};

  List<QueueItem> get queue => List.unmodifiable(_queue);
  int get maxConcurrent => _maxConcurrent;
  bool get isGloballyPaused => _isGloballyPaused;

  /// Number of items currently downloading.
  int get activeCount =>
      _queue.where((i) => i.status == QueueItemStatus.downloading).length;

  /// Number of items waiting to download.
  int get pendingCount =>
      _queue.where((i) => i.status == QueueItemStatus.queued).length;

  /// Number of items that have completed.
  int get completedCount =>
      _queue.where((i) => i.status == QueueItemStatus.completed).length;

  /// Number of items that failed.
  int get failedCount =>
      _queue.where((i) => i.status == QueueItemStatus.failed).length;

  /// Set maximum concurrent downloads.
  set maxConcurrent(int value) {
    _maxConcurrent = value.clamp(1, 5);
    _processQueue();
  }

  /// Initialize the manager by loading persisted queue items.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final items = await _db.getActiveQueueItems();
    _queue.addAll(items);

    // Reset any items that were "downloading" when the app closed back to "queued"
    // since we can't resume HTTP streams across restarts.
    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].status == QueueItemStatus.downloading) {
        _queue[i] = _queue[i].copyWith(
          status: QueueItemStatus.queued,
          progress: 0.0,
        );
        await _db.updateQueueItem(_queue[i]);
      }
    }

    // Wire up network monitor callbacks
    if (networkMonitor != null) {
      networkMonitor!.onDownloadsShouldPause = _pauseForWifi;
      networkMonitor!.onDownloadsCanResume = _resumeAfterWifi;

      // If WiFi-only is enabled and we're not on WiFi, pause immediately
      if (networkMonitor!.wifiOnlyEnabled && !networkMonitor!.isOnWifi) {
        _pauseForWifi();
      }
    }

    notifyListeners();
    _processQueue();
  }

  /// Get a stream of updates for a specific queue item.
  Stream<QueueItem> watchItem(int itemId) {
    _itemControllers.putIfAbsent(
      itemId,
      () => StreamController<QueueItem>.broadcast(),
    );
    return _itemControllers[itemId]!.stream;
  }

  /// Add a single video URL to the queue.
  Future<QueueItem> addToQueue({
    required String url,
    required String title,
    String? thumbnailUrl,
    int? videoIndex,
    String? formatId,
    String? formatLabel,
    String? subtitleLang,
    String? subtitleFormat,
    bool embedSubtitles = false,
    bool downloadSidecarSubtitles = false,
  }) async {
    final item = QueueItem(
      url: url,
      platform: DownloadRecord.detectPlatform(url),
      title: title,
      thumbnailUrl: thumbnailUrl,
      videoIndex: videoIndex,
      formatId: formatId,
      formatLabel: formatLabel,
      subtitleLang: subtitleLang,
      subtitleFormat: subtitleFormat,
      embedSubtitles: embedSubtitles,
      downloadSidecarSubtitles: downloadSidecarSubtitles,
      createdAt: DateTime.now(),
    );

    final id = await _db.insertQueueItem(item);
    final savedItem = item.copyWith(id: id);

    _queue.add(savedItem);
    notifyListeners();
    _processQueue();

    return savedItem;
  }

  /// Add multiple items to the queue (e.g., from a media group).
  Future<List<QueueItem>> addBatchToQueue(List<QueueItem> items) async {
    final savedItems = <QueueItem>[];
    for (final item in items) {
      final id = await _db.insertQueueItem(item);
      final savedItem = item.copyWith(id: id);
      savedItems.add(savedItem);
      _queue.add(savedItem);
    }
    notifyListeners();
    _processQueue();
    return savedItems;
  }

  /// Pause a specific download.
  Future<void> pauseItem(int itemId) async {
    final index = _queue.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _queue[index];
    if (item.status != QueueItemStatus.downloading) return;

    // Cancel the active download
    _cancelActiveDownload(itemId);

    _queue[index] = item.copyWith(status: QueueItemStatus.paused);
    await _db.updateQueueItem(_queue[index]);
    _notifyItemUpdate(_queue[index]);
    notifyListeners();
  }

  /// Resume a paused download.
  Future<void> resumeItem(int itemId) async {
    final index = _queue.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _queue[index];
    if (item.status != QueueItemStatus.paused) return;

    _queue[index] = item.copyWith(
      status: QueueItemStatus.queued,
      retryCount: 0,
    );
    await _db.updateQueueItem(_queue[index]);
    _notifyItemUpdate(_queue[index]);
    notifyListeners();
    _processQueue();
  }

  /// Retry a failed download.
  Future<void> retryItem(int itemId) async {
    final index = _queue.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _queue[index];
    if (item.status != QueueItemStatus.failed) return;

    _queue[index] = item.copyWith(
      status: QueueItemStatus.queued,
      progress: 0.0,
      errorMessage: null,
      errorCode: null,
      retryCount: item.retryCount + 1,
    );
    await _db.updateQueueItem(_queue[index]);
    _notifyItemUpdate(_queue[index]);
    notifyListeners();
    _processQueue();
  }

  /// Cancel and remove a queue item.
  Future<void> cancelItem(int itemId) async {
    _cancelActiveDownload(itemId);

    final index = _queue.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    _queue[index] = _queue[index].copyWith(status: QueueItemStatus.cancelled);
    await _db.updateQueueItem(_queue[index]);
    _notifyItemUpdate(_queue[index]);
    _queue.removeAt(index);
    notifyListeners();
    _processQueue();
  }

  /// Remove a completed/failed/cancelled item from the list.
  Future<void> removeItem(int itemId) async {
    final index = _queue.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _queue[index];
    if (item.isActive) {
      _cancelActiveDownload(itemId);
    }

    await _db.deleteQueueItem(itemId);
    _queue.removeAt(index);
    _disposeItemController(itemId);
    notifyListeners();
  }

  /// Pause all active downloads.
  Future<void> pauseAll() async {
    _isGloballyPaused = true;
    for (final item in _queue) {
      if (item.status == QueueItemStatus.downloading) {
        await pauseItem(item.id!);
      }
    }
    notifyListeners();
  }

  /// Resume all paused downloads.
  Future<void> resumeAll() async {
    _isGloballyPaused = false;
    for (final item in _queue) {
      if (item.status == QueueItemStatus.paused) {
        await resumeItem(item.id!);
      }
    }
    notifyListeners();
  }

  /// Clear all completed, failed, and cancelled items from the queue view.
  Future<void> clearFinished() async {
    await _db.clearFinishedQueueItems();
    _queue.removeWhere(
      (item) =>
          item.status == QueueItemStatus.completed ||
          item.status == QueueItemStatus.failed ||
          item.status == QueueItemStatus.cancelled,
    );
    notifyListeners();
  }

  /// Process the queue - start downloads up to the concurrent limit.
  void _processQueue() {
    if (_isGloballyPaused) return;

    // If WiFi-only is enabled and we're not on WiFi, don't start new downloads
    if (networkMonitor != null &&
        networkMonitor!.wifiOnlyEnabled &&
        !networkMonitor!.isOnWifi) {
      return;
    }

    final downloading =
        _queue.where((i) => i.status == QueueItemStatus.downloading).length;

    final slotsAvailable = _maxConcurrent - downloading;
    if (slotsAvailable <= 0) return;

    final queued =
        _queue
            .where((i) => i.status == QueueItemStatus.queued)
            .take(slotsAvailable)
            .toList();

    for (final item in queued) {
      _startDownload(item);
    }
  }

  /// Start downloading a specific queue item.
  Future<void> _startDownload(QueueItem item) async {
    if (item.id == null) return;

    final id = item.id!;
    final index = _queue.indexWhere((i) => i.id == id);
    if (index == -1) return;

    // Update to downloading
    _queue[index] = item.copyWith(
      status: QueueItemStatus.downloading,
      startedAt: DateTime.now(),
    );
    await _db.updateQueueItem(_queue[index]);
    _notifyItemUpdate(_queue[index]);
    notifyListeners();

    // Build endpoint
    final String endpoint;
    final formatParam =
        item.formatId != null
            ? "&format_id=${Uri.encodeComponent(item.formatId!)}"
            : "";
    // Resolve filename template for this platform
    final template = FilenameTemplate.effectiveTemplate(item.platform);
    final templateParam = "&filename_template=${Uri.encodeComponent(template)}";
    // Subtitle parameters
    final subtitleParam =
        item.subtitleLang != null
            ? "&subtitle_lang=${Uri.encodeComponent(item.subtitleLang!)}&embed_subtitles=${item.embedSubtitles}${item.subtitleFormat != null ? '&subtitle_format=${Uri.encodeComponent(item.subtitleFormat!)}' : ''}"
            : "";
    if (item.videoIndex != null) {
      endpoint =
          "$_backendBaseUrl/download-index?url=${Uri.encodeComponent(item.url)}&index=${item.videoIndex}$formatParam$templateParam$subtitleParam";
    } else {
      endpoint =
          "$_backendBaseUrl/download?url=${Uri.encodeComponent(item.url)}$formatParam$templateParam$subtitleParam";
    }

    final activeDownload = _ActiveDownload();
    _activeDownloads[id] = activeDownload;

    try {
      final request = http.Request('GET', Uri.parse(endpoint));

      // Attach platform auth token if available
      final platform = _queue[index].platform;
      final authToken = await _getAuthTokenForPlatform(platform);
      if (authToken != null) {
        request.headers['X-Auth-Token'] = authToken;
      }
      final client = http.Client();
      activeDownload.client = client;

      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 120));

      if (activeDownload.cancelled) {
        client.close();
        return;
      }

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          final textBody = await response.stream.bytesToString();
          final apiError = _parseApiError(textBody, response.statusCode);
          await _handleDownloadError(
            id,
            apiError.message,
            apiError.errorCode,
            apiError.retryable,
          );
          client.close();
          return;
        }

        final contentLength = response.contentLength;
        int receivedBytes = 0;
        List<int> bytes = [];

        final downloadDir = await _getDownloadDir();
        // Use a sanitized version of the title for the local filename
        final safeName = _sanitizeLocalFilename(item.title);
        final ext = _getExtensionForFormat(item.formatId);
        final filePath =
            "$downloadDir/${safeName}_${DateTime.now().millisecondsSinceEpoch}${item.videoIndex != null ? '_${item.videoIndex}' : ''}.$ext";
        final file = File(filePath);

        await for (final chunk in response.stream) {
          if (activeDownload.cancelled) {
            client.close();
            return;
          }

          bytes.addAll(chunk);
          receivedBytes += chunk.length;

          if (contentLength != null && contentLength > 0) {
            final progress = receivedBytes / contentLength;
            _updateProgress(id, progress, receivedBytes);
          }
        }

        await file.writeAsBytes(bytes);
        await _publishToDownloads(filePath, file.uri.pathSegments.last, ext);

        // Download sidecar subtitles if requested
        if (item.downloadSidecarSubtitles &&
            item.subtitleLang != null &&
            item.subtitleFormat != null) {
          try {
            final subEndpoint =
                "$_backendBaseUrl/download-subtitles?url=${Uri.encodeComponent(item.url)}&lang=${item.subtitleLang}&format=${item.subtitleFormat}";
            final subResponse = await http
                .get(Uri.parse(subEndpoint))
                .timeout(const Duration(seconds: 30));
            if (subResponse.statusCode == 200) {
              final downloadDir = await _getDownloadDir();
              final safeName = _sanitizeLocalFilename(item.title);
              final subExt = item.subtitleFormat!;
              final subFilePath =
                  "$downloadDir/${safeName}_${DateTime.now().millisecondsSinceEpoch}.${item.subtitleLang}.$subExt";
              final subFile = File(subFilePath);
              await subFile.writeAsBytes(subResponse.bodyBytes);
            }
          } catch (e) {
            // Non-fatal: subtitle download failure shouldn't fail the main download
          }
        }

        // Success
        final idx = _queue.indexWhere((i) => i.id == id);
        if (idx == -1) {
          client.close();
          return;
        }

        _queue[idx] = _queue[idx].copyWith(
          status: QueueItemStatus.completed,
          progress: 1.0,
          filePath: filePath,
          fileSizeBytes: receivedBytes,
          completedAt: DateTime.now(),
          downloadedBytes: receivedBytes,
        );
        await _db.updateQueueItem(_queue[idx]);
        await _recordDownload(_queue[idx]);

        _notifyItemUpdate(_queue[idx]);
        _activeDownloads.remove(id);
        notifyListeners();
        _processQueue();

        client.close();
      } else {
        final textBody = await response.stream.bytesToString();
        final apiError = _parseApiError(textBody, response.statusCode);
        await _handleDownloadError(
          id,
          apiError.message,
          apiError.errorCode,
          apiError.retryable,
        );
        client.close();
      }
    } catch (e) {
      if (activeDownload.cancelled) return;

      final apiError = _classifyException(e);
      await _handleDownloadError(
        id,
        apiError.message,
        apiError.errorCode,
        apiError.retryable,
      );
    }
  }

  /// Handle a download error with retry logic.
  Future<void> _handleDownloadError(
    int itemId,
    String message,
    String errorCode,
    bool retryable,
  ) async {
    final index = _queue.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    _queue[index] = _queue[index].copyWith(
      status: QueueItemStatus.failed,
      errorMessage: message,
      errorCode: errorCode,
      retryable: retryable,
    );
    await _db.updateQueueItem(_queue[index]);
    await _recordDownload(_queue[index]);

    _activeDownloads.remove(itemId);
    _notifyItemUpdate(_queue[index]);
    notifyListeners();

    // Auto-retry if retryable and under max retries
    if (retryable && _queue[index].retryCount < _queue[index].maxRetries) {
      final delay = Duration(seconds: min(1 << _queue[index].retryCount, 8));
      await Future.delayed(delay);

      final retryIndex = _queue.indexWhere((i) => i.id == itemId);
      if (retryIndex != -1 &&
          _queue[retryIndex].status == QueueItemStatus.failed) {
        _queue[retryIndex] = _queue[retryIndex].copyWith(
          status: QueueItemStatus.queued,
          progress: 0.0,
          errorMessage: null,
          errorCode: null,
          retryCount: _queue[retryIndex].retryCount + 1,
        );
        await _db.updateQueueItem(_queue[retryIndex]);
        _notifyItemUpdate(_queue[retryIndex]);
        notifyListeners();
        _processQueue();
      }
    } else {
      _processQueue();
    }
  }

  /// Update progress for a downloading item with speed calculation.
  void _updateProgress(int itemId, double progress, int downloadedBytes) {
    final index = _queue.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    // Update speed calculation on the item
    _queue[index].updateSpeed(downloadedBytes);

    _queue[index] = _queue[index].copyWith(
      progress: progress,
      downloadedBytes: downloadedBytes,
      speedBps: _queue[index].speedBps,
    );

    // Throttled DB update (only write every ~5% progress change)
    if ((progress * 20).floor() != ((_queue[index].progress * 20).floor())) {
      _db.updateQueueItemProgress(
        itemId,
        status: QueueItemStatus.downloading,
        progress: progress,
        downloadedBytes: downloadedBytes,
      );
    }

    _notifyItemUpdate(_queue[index]);
    notifyListeners();
  }

  /// Cancel an active download by its item ID.
  void _cancelActiveDownload(int itemId) {
    final active = _activeDownloads.remove(itemId);
    if (active != null) {
      active.cancelled = true;
      active.client?.close();
    }
  }

  /// Record a download to the history database.
  Future<void> _recordDownload(QueueItem item) async {
    try {
      await _db.insertRecord(
        DownloadRecord(
          url: item.url,
          platform: item.platform,
          title: item.title,
          filePath: item.filePath ?? '',
          fileSizeBytes: item.fileSizeBytes,
          status:
              item.status == QueueItemStatus.completed ? 'completed' : 'failed',
          errorMessage: item.errorMessage,
          downloadedAt: DateTime.now(),
          thumbnailUrl: item.thumbnailUrl,
        ),
      );
    } catch (e) {
      debugPrint('Failed to record download: $e');
    }
  }

  /// Get the download directory.
  Future<String> _getDownloadDir() async {
    Directory baseDir;
    if (Platform.isAndroid) {
      baseDir =
          (await getExternalStorageDirectory()) ??
          await getApplicationDocumentsDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final downloadDir = Directory('${baseDir.path}/x_video_downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<void> _publishToDownloads(
    String filePath,
    String displayName,
    String extension,
  ) async {
    if (!Platform.isAndroid) return;

    final mimeType = extension == 'mp3' ? 'audio/mpeg' : 'video/mp4';
    try {
      await _mediaChannel.invokeMethod('publishToDownloads', {
        'path': filePath,
        'displayName': displayName,
        'mimeType': mimeType,
      });
    } catch (e) {
      debugPrint('Failed to publish download to public Downloads: $e');
      try {
        await _mediaChannel.invokeMethod('scanFile', {'path': filePath});
      } catch (scanError) {
        debugPrint('Failed to scan downloaded file: $scanError');
      }
    }
  }

  /// Sanitize a string for use as a local filename.
  String _sanitizeLocalFilename(String name) {
    // Remove characters not safe for filenames
    var safe = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '');
    // Collapse whitespace
    safe = safe.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Remove leading/trailing dots and spaces
    while (safe.endsWith('.') || safe.endsWith(' ')) {
      safe = safe.substring(0, safe.length - 1);
    }
    while (safe.startsWith('.') || safe.startsWith(' ')) {
      safe = safe.substring(1);
    }
    // Truncate to reasonable length
    if (safe.length > 80) {
      safe = safe.substring(0, 80);
    }
    return safe.isEmpty ? 'video' : safe;
  }

  /// Get the file extension for a given format ID.
  String _getExtensionForFormat(String? formatId) {
    if (formatId == null) return 'mp4';
    final lower = formatId.toLowerCase();
    if (lower.contains('mp3')) return 'mp3';
    if (lower.contains('m4a')) return 'm4a';
    if (lower.contains('webm')) return 'webm';
    if (lower.contains('ogg')) return 'ogg';
    if (lower.startsWith('a') || lower.contains('audio')) return 'm4a';
    return 'mp4';
  }

  /// Notify listeners for a specific item's stream.
  void _notifyItemUpdate(QueueItem item) {
    final controller = _itemControllers[item.id];
    if (controller != null && !controller.isClosed) {
      controller.add(item);
    }
  }

  /// Dispose a stream controller for an item.
  void _disposeItemController(int itemId) {
    final controller = _itemControllers.remove(itemId);
    controller?.close();
  }

  /// Parse an API error from a response body.
  _ApiError _parseApiError(String body, int statusCode) {
    try {
      final data = json.decode(body) as Map<String, dynamic>;
      final detail = data['detail'];
      return _ApiError(
        message:
            data['error'] as String? ??
            (detail is String ? detail : null) ??
            'Request failed (HTTP $statusCode)',
        errorCode: data['error_code'] as String? ?? 'http_$statusCode',
        retryable: data['retryable'] as bool? ?? false,
      );
    } catch (_) {
      if (statusCode >= 500) {
        return const _ApiError(
          message: 'Server error. Please try again later.',
          errorCode: 'server_error',
          retryable: true,
        );
      }
      return _ApiError(
        message: body.isNotEmpty ? body : 'Request failed (HTTP $statusCode)',
        errorCode: 'http_$statusCode',
        retryable: false,
      );
    }
  }

  /// Classify a client-side exception.
  _ApiError _classifyException(Object e) {
    final msg = e.toString().toLowerCase();
    if (e is SocketException || msg.contains('connection')) {
      return const _ApiError(
        message: 'No internet connection.',
        errorCode: 'network_error',
        retryable: true,
      );
    }
    if (e is TimeoutException || msg.contains('timeout')) {
      return const _ApiError(
        message: 'Request timed out.',
        errorCode: 'timeout',
        retryable: true,
      );
    }
    return _ApiError(
      message: 'Error: $e',
      errorCode: 'unknown',
      retryable: false,
    );
  }

  /// Get a valid auth token for a platform, refreshing if needed.
  Future<String?> _getAuthTokenForPlatform(String platform) async {
    if (authService == null) return null;

    // Map download platform names to auth platform names
    final authPlatform = _mapToAuthPlatform(platform);
    if (authPlatform == null) return null;

    return authService!.getValidAccessToken(authPlatform);
  }

  /// Map download platform names to auth platform names.
  String? _mapToAuthPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'x/twitter':
      case 'twitter':
        return 'twitter';
      case 'instagram':
        return 'instagram';
      default:
        return null;
    }
  }

  /// Pause all active downloads because WiFi was disconnected.
  void _pauseForWifi() {
    for (final item in _queue) {
      if (item.status == QueueItemStatus.downloading && item.id != null) {
        _wifiPausedItems.add(item.id!);
        pauseItem(item.id!);
      }
    }
  }

  /// Resume downloads that were paused due to WiFi disconnect.
  void _resumeAfterWifi() {
    final toResume = _wifiPausedItems.toList();
    _wifiPausedItems.clear();
    for (final itemId in toResume) {
      final index = _queue.indexWhere((i) => i.id == itemId);
      if (index != -1 && _queue[index].status == QueueItemStatus.paused) {
        resumeItem(itemId);
      }
    }
  }

  /// Whether a specific item was paused by the WiFi monitor (not the user).
  bool isWifiPaused(int itemId) => _wifiPausedItems.contains(itemId);

  @override
  void dispose() {
    for (final controller in _itemControllers.values) {
      controller.close();
    }
    _itemControllers.clear();
    for (final active in _activeDownloads.values) {
      active.cancelled = true;
      active.client?.close();
    }
    _activeDownloads.clear();
    super.dispose();
  }
}

/// Tracks an active HTTP download for cancellation support.
class _ActiveDownload {
  http.Client? client;
  bool cancelled = false;
}

/// Internal error representation.
class _ApiError {
  final String message;
  final String errorCode;
  final bool retryable;

  const _ApiError({
    required this.message,
    required this.errorCode,
    this.retryable = false,
  });
}
