I'll continue implementing the WiFi-only downloads feature. Let me first explore the codebase to understand the existing structure.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Explore codebase structure and understand existing download system",
      "status": "in_progress",
      "activeForm": "Exploring codebase structure"
    },
    {
      "content": "Add connectivity_plus dependency to pubspec.yaml",
      "status": "pending",
      "activeForm": "Adding connectivity_plus dependency"
    },
    {
      "content": "Create network connectivity monitor service",
      "status": "pending",
      "activeForm": "Creating network connectivity monitor"
    },
    {
      "content": "Add WiFi-only setting to preferences/settings",
      "status": "pending",
      "activeForm": "Adding WiFi-only setting"
    },
    {
      "content": "Integrate network monitor with download queue manager",
      "status": "pending",
      "activeForm": "Integrating network monitor with downloads"
    },
    {
      "content": "Add WiFi-only toggle UI in settings screen",
      "status": "pending",
      "activeForm": "Adding WiFi-only toggle UI"
    },
    {
      "content": "Test and verify the implementation",
      "status": "pending",
      "activeForm": "Testing implementation"
    }
  ]
}

🔧 Tool: Glob
Input: {
  "pattern": "x_video_downloader_flutter_frontend/lib/**/*.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\pubspec.yaml"
}
Good, I have the tools working now. Let me read the key files to understand the download system.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\queue_item.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\background_download_service.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart"
}
Now let me also read the download queue screen and the download database to understand the settings/preferences setup.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_screen.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart"
}
Now I have a thorough understanding of the codebase. Let me update my plan and start implementing.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and understand existing download system",
      "status": "completed"
    },
    {
      "activeForm": "Adding connectivity_plus dependency",
      "content": "Add connectivity_plus dependency to pubspec.yaml",
      "status": "in_progress"
    },
    {
      "activeForm": "Creating network connectivity monitor",
      "content": "Create network connectivity monitor service",
      "status": "pending"
    },
    {
      "activeForm": "Adding WiFi-only setting persistence",
      "content": "Add WiFi-only setting persistence (SharedPreferences)",
      "status": "pending"
    },
    {
      "activeForm": "Integrating network monitor with downloads",
      "content": "Integrate network monitor with download queue manager",
      "status": "pending"
    },
    {
      "activeForm": "Adding WiFi-only toggle UI",
      "content": "Add WiFi-only toggle UI in download queue screen",
      "status": "pending"
    },
    {
      "activeForm": "Testing implementation",
      "content": "Test and verify the implementation compiles",
      "status": "pending"
    }
  ]
}
Let me add the `connectivity_plus` and `shared_preferences` dependencies to `pubspec.yaml`.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\pubspec.yaml",
  "old_string": "  flutter_background_service: ^5.1.0\n  flutter_local_notifications: ^19.2.0",
  "new_string": "  flutter_background_service: ^5.1.0\n  flutter_local_notifications: ^19.2.0\n  connectivity_plus: ^6.1.4\n  shared_preferences: ^2.5.3"
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and understand existing download system",
      "status": "completed"
    },
    {
      "activeForm": "Adding connectivity_plus dependency",
      "content": "Add connectivity_plus dependency to pubspec.yaml",
      "status": "completed"
    },
    {
      "activeForm": "Creating network connectivity monitor",
      "content": "Create network connectivity monitor service",
      "status": "in_progress"
    },
    {
      "activeForm": "Adding WiFi-only setting persistence",
      "content": "Add WiFi-only setting persistence (SharedPreferences)",
      "status": "pending"
    },
    {
      "activeForm": "Integrating network monitor with downloads",
      "content": "Integrate network monitor with download queue manager",
      "status": "pending"
    },
    {
      "activeForm": "Adding WiFi-only toggle UI",
      "content": "Add WiFi-only toggle UI in download queue screen",
      "status": "pending"
    },
    {
      "activeForm": "Testing implementation",
      "content": "Test and verify the implementation compiles",
      "status": "pending"
    }
  ]
}
Now let me create the network connectivity monitor service.

🔧 Tool: Write
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\network_monitor.dart",
  "content": "import 'dart:async';\n\nimport 'package:connectivity_plus/connectivity_plus.dart';\nimport 'package:flutter/foundation.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\n\nconst String _wifiOnlyPrefKey = 'wifi_only_enabled';\n\n/// Monitors network connectivity and enforces WiFi-only download policy.\n///\n/// When WiFi-only mode is enabled, downloads are paused when the device\n/// switches to mobile data and auto-resumed when WiFi is reconnected.\nclass NetworkMonitor extends ChangeNotifier {\n  final Connectivity _connectivity = Connectivity();\n\n  /// Whether WiFi-only mode is enabled in settings.\n  bool _wifiOnlyEnabled = false;\n  bool get wifiOnlyEnabled => _wifiOnlyEnabled;\n\n  /// Whether the device currently has a WiFi connection.\n  bool _isOnWifi = true;\n  bool get isOnWifi => _isOnWifi;\n\n  /// Whether downloads should be allowed right now.\n  /// True if WiFi-only is off, or if WiFi-only is on and device is on WiFi.\n  bool get downloadsAllowed => !_wifiOnlyEnabled || _isOnWifi;\n\n  StreamSubscription<List<ConnectivityResult>>? _subscription;\n\n  /// Callback invoked when network changes and downloads need to pause.\n  VoidCallback? onDownloadsShouldPause;\n\n  /// Callback invoked when network changes and downloads can resume.\n  VoidCallback? onDownloadsCanResume;\n\n  /// Initialize the monitor: load saved preference and start listening.\n  Future<void> init() async {\n    final prefs = await SharedPreferences.getInstance();\n    _wifiOnlyEnabled = prefs.getBool(_wifiOnlyPrefKey) ?? false;\n\n    // Check current connectivity state\n    final results = await _connectivity.checkConnectivity();\n    _isOnWifi = results.any((r) => r == ConnectivityResult.wifi);\n\n    _subscription = _connectivity.onConnectivityChanged.listen(\n      _onConnectivityChanged,\n    );\n\n    notifyListeners();\n  }\n\n  /// Enable or disable WiFi-only mode and persist the setting.\n  Future<void> setWifiOnly(bool enabled) async {\n    if (_wifiOnlyEnabled == enabled) return;\n\n    _wifiOnlyEnabled = enabled;\n    final prefs = await SharedPreferences.getInstance();\n    await prefs.setBool(_wifiOnlyPrefKey, enabled);\n\n    if (enabled && !_isOnWifi) {\n      // Just enabled WiFi-only but not on WiFi — pause downloads\n      onDownloadsShouldPause?.call();\n    } else if (!enabled) {\n      // Just disabled WiFi-only — resume any paused downloads\n      onDownloadsCanResume?.call();\n    }\n\n    notifyListeners();\n  }\n\n  void _onConnectivityChanged(List<ConnectivityResult> results) {\n    final wasOnWifi = _isOnWifi;\n    _isOnWifi = results.any((r) => r == ConnectivityResult.wifi);\n\n    if (_isOnWifi == wasOnWifi) return; // No change relevant to us\n\n    if (_wifiOnlyEnabled) {\n      if (_isOnWifi) {\n        // Switched to WiFi — resume downloads\n        onDownloadsCanResume?.call();\n      } else {\n        // Switched away from WiFi — pause downloads\n        onDownloadsShouldPause?.call();\n      }\n    }\n\n    notifyListeners();\n  }\n\n  @override\n  void dispose() {\n    _subscription?.cancel();\n    super.dispose();\n  }\n}\n"
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and understand existing download system",
      "status": "completed"
    },
    {
      "activeForm": "Adding connectivity_plus dependency",
      "content": "Add connectivity_plus dependency to pubspec.yaml",
      "status": "completed"
    },
    {
      "activeForm": "Creating network connectivity monitor",
      "content": "Create network connectivity monitor service",
      "status": "completed"
    },
    {
      "activeForm": "Adding WiFi-only setting persistence",
      "content": "Add WiFi-only setting persistence (SharedPreferences)",
      "status": "completed"
    },
    {
      "activeForm": "Integrating network monitor with downloads",
      "content": "Integrate network monitor with download queue manager",
      "status": "in_progress"
    },
    {
      "activeForm": "Adding WiFi-only toggle UI",
      "content": "Add WiFi-only toggle UI in download queue screen",
      "status": "pending"
    },
    {
      "activeForm": "Testing implementation",
      "content": "Test and verify the implementation compiles",
      "status": "pending"
    }
  ]
}
Now let me integrate the network monitor with the download queue manager. I need to add the `_wifiPausedItems` tracking so we know which items were paused by WiFi disconnect (vs user pause).

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 20
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "old_string": "import 'auth_service.dart';\nimport 'background_download_service.dart';\nimport 'download_database.dart';\nimport 'download_record.dart';\nimport 'queue_item.dart';",
  "new_string": "import 'auth_service.dart';\nimport 'background_download_service.dart';\nimport 'download_database.dart';\nimport 'download_record.dart';\nimport 'network_monitor.dart';\nimport 'queue_item.dart';"
}
Now add the network monitor field and WiFi-paused tracking set to the class.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "old_string": "  /// Background service for Android foreground notifications.\n  final BackgroundDownloadService _bgService = BackgroundDownloadService();\n  bool _bgServiceStarted = false;",
  "new_string": "  /// Background service for Android foreground notifications.\n  final BackgroundDownloadService _bgService = BackgroundDownloadService();\n  bool _bgServiceStarted = false;\n\n  /// Network monitor for WiFi-only mode.\n  NetworkMonitor? networkMonitor;\n\n  /// IDs of items paused by WiFi disconnect (not user-initiated).\n  final Set<int> _wifiPausedItems = {};"
}
Now I need to add the WiFi-aware methods and wire them up. Let me add `pauseForWifi()` and `resumeAfterWifi()` methods, and modify `_processQueue` to check WiFi status. Let me also modify `init()` to wire up the network monitor callbacks.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "old_string": "  /// Initialize the manager by loading persisted queue items.\n  Future<void> init() async {\n    if (_initialized) return;\n    _initialized = true;\n\n    final items = await _db.getActiveQueueItems();\n    _queue.addAll(items);\n\n    // Reset any items that were \"downloading\" when the app closed back to \"queued\"\n    // since we can't resume HTTP streams across restarts.\n    for (int i = 0; i < _queue.length; i++) {\n      if (_queue[i].status == QueueItemStatus.downloading) {\n        _queue[i] = _queue[i].copyWith(\n          status: QueueItemStatus.queued,\n          progress: 0.0,\n        );\n        await _db.updateQueueItem(_queue[i]);\n      }\n    }\n\n    notifyListeners();\n    _processQueue();\n  }",
  "new_string": "  /// Initialize the manager by loading persisted queue items.\n  Future<void> init() async {\n    if (_initialized) return;\n    _initialized = true;\n\n    final items = await _db.getActiveQueueItems();\n    _queue.addAll(items);\n\n    // Reset any items that were \"downloading\" when the app closed back to \"queued\"\n    // since we can't resume HTTP streams across restarts.\n    for (int i = 0; i < _queue.length; i++) {\n      if (_queue[i].status == QueueItemStatus.downloading) {\n        _queue[i] = _queue[i].copyWith(\n          status: QueueItemStatus.queued,\n          progress: 0.0,\n        );\n        await _db.updateQueueItem(_queue[i]);\n      }\n    }\n\n    // Wire up network monitor callbacks\n    if (networkMonitor != null) {\n      networkMonitor!.onDownloadsShouldPause = _pauseForWifi;\n      networkMonitor!.onDownloadsCanResume = _resumeAfterWifi;\n\n      // If WiFi-only is enabled and we're not on WiFi, pause immediately\n      if (networkMonitor!.wifiOnlyEnabled && !networkMonitor!.isOnWifi) {\n        _pauseForWifi();\n      }\n    }\n\n    notifyListeners();\n    _processQueue();\n  }"
}
Now modify `_processQueue` to check WiFi status before starting downloads.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "old_string": "  /// Process the queue - start downloads up to the concurrent limit.\n  void _processQueue() {\n    if (_isGloballyPaused) return;\n\n    final downloading = _queue\n        .where((i) => i.status == QueueItemStatus.downloading)\n        .length;",
  "new_string": "  /// Process the queue - start downloads up to the concurrent limit.\n  void _processQueue() {\n    if (_isGloballyPaused) return;\n\n    // If WiFi-only is enabled and we're not on WiFi, don't start new downloads\n    if (networkMonitor != null &&\n        networkMonitor!.wifiOnlyEnabled &&\n        !networkMonitor!.isOnWifi) {\n      return;\n    }\n\n    final downloading = _queue\n        .where((i) => i.status == QueueItemStatus.downloading)\n        .length;"
}
Now add the WiFi pause/resume methods. I'll add them right before the `dispose` method.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "old_string": "  @override",
  "new_string": "  /// Pause all active downloads because WiFi was disconnected.\n  void _pauseForWifi() {\n    for (final item in _queue) {\n      if (item.status == QueueItemStatus.downloading && item.id != null) {\n        _wifiPausedItems.add(item.id!);\n        pauseItem(item.id!);\n      }\n    }\n  }\n\n  /// Resume downloads that were paused due to WiFi disconnect.\n  void _resumeAfterWifi() {\n    final toResume = _wifiPausedItems.toList();\n    _wifiPausedItems.clear();\n    for (final itemId in toResume) {\n      final index = _queue.indexWhere((i) => i.id == itemId);\n      if (index != -1 && _queue[index].status == QueueItemStatus.paused) {\n        resumeItem(itemId);\n      }\n    }\n  }\n\n  /// Whether a specific item was paused by the WiFi monitor (not the user).\n  bool isWifiPaused(int itemId) => _wifiPausedItems.contains(itemId);\n\n  @override"
}
Now I need to wire up the `NetworkMonitor` in `main.dart`. Let me update the global instances and initialization.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "import 'download_record.dart';\nimport 'download_history_screen.dart';\nimport 'download_queue_manager.dart';\nimport 'download_queue_screen.dart';\nimport 'queue_item.dart';\nimport 'format_option.dart';\nimport 'auth_service.dart';\nimport 'auth_settings_screen.dart';\nimport 'dart:async';",
  "new_string": "import 'download_record.dart';\nimport 'download_history_screen.dart';\nimport 'download_queue_manager.dart';\nimport 'download_queue_screen.dart';\nimport 'queue_item.dart';\nimport 'format_option.dart';\nimport 'auth_service.dart';\nimport 'auth_settings_screen.dart';\nimport 'network_monitor.dart';\nimport 'dart:async';"
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "// --- Global queue manager ---\nfinal DownloadQueueManager _queueManager = DownloadQueueManager();\n\n// --- Global auth service ---\nfinal AuthService _authService = AuthService();",
  "new_string": "// --- Global queue manager ---\nfinal DownloadQueueManager _queueManager = DownloadQueueManager();\n\n// --- Global auth service ---\nfinal AuthService _authService = AuthService();\n\n// --- Global network monitor ---\nfinal NetworkMonitor _networkMonitor = NetworkMonitor();"
}
Now update the `main()` function to initialize the network monitor and pass it to the queue manager.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "  await _authService.init();\n  _queueManager.authService = _authService;\n  await _queueManager.init();\n  runApp(const MyApp());",
  "new_string": "  await _authService.init();\n  await _networkMonitor.init();\n  _queueManager.authService = _authService;\n  _queueManager.networkMonitor = _networkMonitor;\n  await _queueManager.init();\n  runApp(const MyApp());"
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and understand existing download system",
      "status": "completed"
    },
    {
      "activeForm": "Adding connectivity_plus dependency",
      "content": "Add connectivity_plus dependency to pubspec.yaml",
      "status": "completed"
    },
    {
      "activeForm": "Creating network connectivity monitor",
      "content": "Create network connectivity monitor service",
      "status": "completed"
    },
    {
      "activeForm": "Adding WiFi-only setting persistence",
      "content": "Add WiFi-only setting persistence (SharedPreferences)",
      "status": "completed"
    },
    {
      "activeForm": "Integrating network monitor with downloads",
      "content": "Integrate network monitor with download queue manager",
      "status": "completed"
    },
    {
      "activeForm": "Adding WiFi-only toggle UI",
      "content": "Add WiFi-only toggle UI in download queue screen",
      "status": "in_progress"
    },
    {
      "activeForm": "Testing implementation",
      "content": "Test and verify the implementation compiles",
      "status": "pending"
    }
  ]
}
Now let me add the WiFi-only toggle UI to the download queue screen. I'll add it to the summary bar area alongside the concurrent download setting.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_screen.dart",
  "limit": 20
}
I need to update the `DownloadQueueScreen` to accept the `NetworkMonitor` and add a WiFi-only toggle. Let me update the screen.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_screen.dart",
  "old_string": "import 'package:flutter/material.dart';\nimport 'package:intl/intl.dart';\n\nimport 'download_queue_manager.dart';\nimport 'queue_item.dart';\n\n/// Screen showing the download queue with pause/resume/retry controls.\nclass DownloadQueueScreen extends StatefulWidget {\n  final DownloadQueueManager queueManager;\n\n  const DownloadQueueScreen({\n    super.key,\n    required this.queueManager,\n  });",
  "new_string": "import 'package:flutter/material.dart';\nimport 'package:intl/intl.dart';\n\nimport 'download_queue_manager.dart';\nimport 'network_monitor.dart';\nimport 'queue_item.dart';\n\n/// Screen showing the download queue with pause/resume/retry controls.\nclass DownloadQueueScreen extends StatefulWidget {\n  final DownloadQueueManager queueManager;\n  final NetworkMonitor networkMonitor;\n\n  const DownloadQueueScreen({\n    super.key,\n    required this.queueManager,\n    required this.networkMonitor,\n  });"
}
Now I need to add the network monitor listener in the state class and update the `_SummaryBar` to include the WiFi-only toggle.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_screen.dart",
  "old_string": "class _DownloadQueueScreenState extends State<DownloadQueueScreen> {\n  @override\n  void initState() {\n    super.initState();\n    widget.queueManager.addListener(_onQueueChanged);\n  }\n\n  @override\n  void dispose() {\n    widget.queueManager.removeListener(_onQueueChanged);\n    super.dispose();\n  }\n\n  void _onQueueChanged() {\n    if (mounted) setState(() {});\n  }",
  "new_string": "class _DownloadQueueScreenState extends State<DownloadQueueScreen> {\n  @override\n  void initState() {\n    super.initState();\n    widget.queueManager.addListener(_onQueueChanged);\n    widget.networkMonitor.addListener(_onQueueChanged);\n  }\n\n  @override\n  void dispose() {\n    widget.queueManager.removeListener(_onQueueChanged);\n    widget.networkMonitor.removeListener(_onQueueChanged);\n    super.dispose();\n  }\n\n  void _onQueueChanged() {\n    if (mounted) setState(() {});\n  }"
}
Now update the `_SummaryBar` widget in the build method to pass the network monitor.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_screen.dart",
  "old_string": "                // Summary bar\n                _SummaryBar(\n                  active: activeItems.length,\n                  queued: queuedItems.length,\n                  completed: completedItems.length,\n                  failed: failedItems.length,\n                  maxConcurrent: widget.queueManager.maxConcurrent,\n                  onMaxConcurrentChanged: (v) =>\n                      widget.queueManager.maxConcurrent = v,\n                ),",
  "new_string": "                // Summary bar\n                _SummaryBar(\n                  active: activeItems.length,\n                  queued: queuedItems.length,\n                  completed: completedItems.length,\n                  failed: failedItems.length,\n                  maxConcurrent: widget.queueManager.maxConcurrent,\n                  onMaxConcurrentChanged: (v) =>\n                      widget.queueManager.maxConcurrent = v,\n                  networkMonitor: widget.networkMonitor,\n                  wifiPausedCount: widget.queueManager.queue\n                      .where((i) =>\n                          i.status == QueueItemStatus.paused &&\n                          i.id != null &&\n                          widget.queueManager.isWifiPaused(i.id!))\n                      .length,\n                ),"
}
Now update the `_SummaryBar` widget to include the WiFi-only toggle.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_screen.dart",
  "old_string": "/// Summary bar showing queue stats and concurrent download setting.\nclass _SummaryBar extends StatelessWidget {\n  final int active;\n  final int queued;\n  final int completed;\n  final int failed;\n  final int maxConcurrent;\n  final ValueChanged<int> onMaxConcurrentChanged;\n\n  const _SummaryBar({\n    required this.active,\n    required this.queued,\n    required this.completed,\n    required this.failed,\n    required this.maxConcurrent,\n    required this.onMaxConcurrentChanged,\n  });\n\n  @override\n  Widget build(BuildContext context) {\n    return Padding(\n      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),\n      child: Row(\n        children: [\n          _StatChip(label: 'Active', count: active, color: Colors.blue),\n          const SizedBox(width: 8),\n          _StatChip(label: 'Queued', count: queued, color: Colors.grey),\n          const SizedBox(width: 8),\n          _StatChip(label: 'Done', count: completed, color: Colors.green),\n          const SizedBox(width: 8),\n          _StatChip(label: 'Failed', count: failed, color: Colors.red),\n          const Spacer(),\n          // Concurrent download selector\n          InkWell(\n            onTap: () => _showConcurrentPicker(context),\n            borderRadius: BorderRadius.circular(8),\n            child: Container(\n              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),\n              decoration: BoxDecoration(\n                border: Border.all(color: Colors.grey[300]!),\n                borderRadius: BorderRadius.circular(8),\n              ),\n              child: Row(\n                mainAxisSize: MainAxisSize.min,\n                children: [\n                  Icon(Icons.settings, size: 14, color: Colors.grey[600]),\n                  const SizedBox(width: 4),\n                  Text(\n                    '$maxConcurrent concurrent',\n                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),\n                  ),\n                ],\n              ),\n            ),\n          ),\n        ],\n      ),\n    );\n  }",
  "new_string": "/// Summary bar showing queue stats, WiFi-only toggle, and concurrent download setting.\nclass _SummaryBar extends StatelessWidget {\n  final int active;\n  final int queued;\n  final int completed;\n  final int failed;\n  final int maxConcurrent;\n  final ValueChanged<int> onMaxConcurrentChanged;\n  final NetworkMonitor networkMonitor;\n  final int wifiPausedCount;\n\n  const _SummaryBar({\n    required this.active,\n    required this.queued,\n    required this.completed,\n    required this.failed,\n    required this.maxConcurrent,\n    required this.onMaxConcurrentChanged,\n    required this.networkMonitor,\n    required this.wifiPausedCount,\n  });\n\n  @override\n  Widget build(BuildContext context) {\n    return Padding(\n      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),\n      child: Column(\n        children: [\n          Row(\n            children: [\n              _StatChip(label: 'Active', count: active, color: Colors.blue),\n              const SizedBox(width: 8),\n              _StatChip(label: 'Queued', count: queued, color: Colors.grey),\n              const SizedBox(width: 8),\n              _StatChip(label: 'Done', count: completed, color: Colors.green),\n              const SizedBox(width: 8),\n              _StatChip(label: 'Failed', count: failed, color: Colors.red),\n              const Spacer(),\n              // Concurrent download selector\n              InkWell(\n                onTap: () => _showConcurrentPicker(context),\n                borderRadius: BorderRadius.circular(8),\n                child: Container(\n                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),\n                  decoration: BoxDecoration(\n                    border: Border.all(color: Colors.grey[300]!),\n                    borderRadius: BorderRadius.circular(8),\n                  ),\n                  child: Row(\n                    mainAxisSize: MainAxisSize.min,\n                    children: [\n                      Icon(Icons.settings, size: 14, color: Colors.grey[600]),\n                      const SizedBox(width: 4),\n                      Text(\n                        '$maxConcurrent concurrent',\n                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),\n                      ),\n                    ],\n                  ),\n                ),\n              ),\n            ],\n          ),\n          // WiFi-only toggle row\n          const SizedBox(height: 4),\n          Row(\n            children: [\n              Icon(\n                networkMonitor.wifiOnlyEnabled ? Icons.wifi : Icons.wifi_off,\n                size: 16,\n                color: networkMonitor.wifiOnlyEnabled\n                    ? (networkMonitor.isOnWifi ? Colors.green : Colors.orange)\n                    : Colors.grey[500],\n              ),\n              const SizedBox(width: 6),\n              Expanded(\n                child: Text(\n                  networkMonitor.wifiOnlyEnabled\n                      ? (networkMonitor.isOnWifi\n                          ? 'WiFi only — connected'\n                          : 'WiFi only — waiting for WiFi ($wifiPausedCount paused)')\n                      : 'WiFi only mode',\n                  style: TextStyle(\n                    fontSize: 12,\n                    color: networkMonitor.wifiOnlyEnabled\n                        ? (networkMonitor.isOnWifi ? Colors.green[700] : Colors.orange[700])\n                        : Colors.grey[600],\n                  ),\n                ),\n              ),\n              SizedBox(\n                height: 28,\n                child: FittedBox(\n                  child: Switch(\n                    value: networkMonitor.wifiOnlyEnabled,\n                    onChanged: (val) => networkMonitor.setWifiOnly(val),\n                    activeColor: Colors.green,\n                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,\n                  ),\n                ),\n              ),\n            ],\n          ),\n        ],\n      ),\n    );\n  }"
}
The file was modified by a linter. Let me re-read it.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_screen.dart"
}
I see the `_SummaryBar` wasn't updated by the linter (it still has the old signature without `networkMonitor` and `wifiPausedCount`). The call site was updated but the class definition wasn't. Let me fix the `_SummaryBar` class now.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_screen.dart",
  "old_string": "/// Summary bar showing queue stats and concurrent download setting.\nclass _SummaryBar extends StatelessWidget {\n  final int active;\n  final int queued;\n  final int completed;\n  final int failed;\n  final int maxConcurrent;\n  final ValueChanged<int> onMaxConcurrentChanged;\n\n  const _SummaryBar({\n    required this.active,\n    required this.queued,\n    required this.completed,\n    required this.failed,\n    required this.maxConcurrent,\n    required this.onMaxConcurrentChanged,\n  });\n\n  @override\n  Widget build(BuildContext context) {\n    return Padding(\n      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),\n      child: Row(\n        children: [\n          _StatChip(label: 'Active', count: active, color: Colors.blue),\n          const SizedBox(width: 8),\n          _StatChip(label: 'Queued', count: queued, color: Colors.grey),\n          const SizedBox(width: 8),\n          _StatChip(label: 'Done', count: completed, color: Colors.green),\n          const SizedBox(width: 8),\n          _StatChip(label: 'Failed', count: failed, color: Colors.red),\n          const Spacer(),\n          // Concurrent download selector\n          InkWell(\n            onTap: () => _showConcurrentPicker(context),\n            borderRadius: BorderRadius.circular(8),\n            child: Container(\n              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),\n              decoration: BoxDecoration(\n                border: Border.all(color: Colors.grey[300]!),\n                borderRadius: BorderRadius.circular(8),\n              ),\n              child: Row(\n                mainAxisSize: MainAxisSize.min,\n                children: [\n                  Icon(Icons.settings, size: 14, color: Colors.grey[600]),\n                  const SizedBox(width: 4),\n                  Text(\n                    '$maxConcurrent concurrent',\n                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),\n                  ),\n                ],\n              ),\n            ),\n          ),\n        ],\n      ),\n    );\n  }",
  "new_string": "/// Summary bar showing queue stats, WiFi-only toggle, and concurrent download setting.\nclass _SummaryBar extends StatelessWidget {\n  final int active;\n  final int queued;\n  final int completed;\n  final int failed;\n  final int maxConcurrent;\n  final ValueChanged<int> onMaxConcurrentChanged;\n  final NetworkMonitor networkMonitor;\n  final int wifiPausedCount;\n\n  const _SummaryBar({\n    required this.active,\n    required this.queued,\n    required this.completed,\n    required this.failed,\n    required this.maxConcurrent,\n    required this.onMaxConcurrentChanged,\n    required this.networkMonitor,\n    required this.wifiPausedCount,\n  });\n\n  @override\n  Widget build(BuildContext context) {\n    return Padding(\n      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),\n      child: Column(\n        children: [\n          Row(\n            children: [\n              _StatChip(label: 'Active', count: active, color: Colors.blue),\n              const SizedBox(width: 8),\n              _StatChip(label: 'Queued', count: queued, color: Colors.grey),\n              const SizedBox(width: 8),\n              _StatChip(label: 'Done', count: completed, color: Colors.green),\n              const SizedBox(width: 8),\n              _StatChip(label: 'Failed', count: failed, color: Colors.red),\n              const Spacer(),\n              // Concurrent download selector\n              InkWell(\n                onTap: () => _showConcurrentPicker(context),\n                borderRadius: BorderRadius.circular(8),\n                child: Container(\n                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),\n                  decoration: BoxDecoration(\n                    border: Border.all(color: Colors.grey[300]!),\n                    borderRadius: BorderRadius.circular(8),\n                  ),\n                  child: Row(\n                    mainAxisSize: MainAxisSize.min,\n                    children: [\n                      Icon(Icons.settings, size: 14, color: Colors.grey[600]),\n                      const SizedBox(width: 4),\n                      Text(\n                        '$maxConcurrent concurrent',\n                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),\n                      ),\n                    ],\n                  ),\n                ),\n              ),\n            ],\n          ),\n          // WiFi-only toggle row\n          const SizedBox(height: 4),\n          Row(\n            children: [\n              Icon(\n                networkMonitor.wifiOnlyEnabled ? Icons.wifi : Icons.wifi_off,\n                size: 16,\n                color: networkMonitor.wifiOnlyEnabled\n                    ? (networkMonitor.isOnWifi ? Colors.green : Colors.orange)\n                    : Colors.grey[500],\n              ),\n              const SizedBox(width: 6),\n              Expanded(\n                child: Text(\n                  networkMonitor.wifiOnlyEnabled\n                      ? (networkMonitor.isOnWifi\n                          ? 'WiFi only — connected'\n                          : 'WiFi only — waiting for WiFi ($wifiPausedCount paused)')\n                      : 'WiFi only mode',\n                  style: TextStyle(\n                    fontSize: 12,\n                    color: networkMonitor.wifiOnlyEnabled\n                        ? (networkMonitor.isOnWifi ? Colors.green[700] : Colors.orange[700])\n                        : Colors.grey[600],\n                  ),\n                ),\n              ),\n              SizedBox(\n                height: 28,\n                child: FittedBox(\n                  child: Switch(\n                    value: networkMonitor.wifiOnlyEnabled,\n                    onChanged: (val) => networkMonitor.setWifiOnly(val),\n                    activeColor: Colors.green,\n                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,\n                  ),\n                ),\n              ),\n            ],\n          ),\n        ],\n      ),\n    );\n  }"
}
Now I need to update all the places in `main.dart` that navigate to `DownloadQueueScreen` to also pass the `_networkMonitor`.

🔧 Tool: Grep
Input: {
  "pattern": "DownloadQueueScreen\\(",
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "output_mode": "content",
  "-n": true
}
Three places. Let me update all of them.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "offset": 690,
  "limit": 10
}

🔧 Tool: Edit
Input: {
  "replace_all": true,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "                      builder: (_) => DownloadQueueScreen(\n                        queueManager: _queueManager,\n                      ),",
  "new_string": "                      builder: (_) => DownloadQueueScreen(\n                        queueManager: _queueManager,\n                        networkMonitor: _networkMonitor,\n                      ),"
}
Now let me run `flutter pub get` to install the new dependencies.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and understand existing download system",
      "status": "completed"
    },
    {
      "activeForm": "Adding connectivity_plus dependency",
      "content": "Add connectivity_plus dependency to pubspec.yaml",
      "status": "completed"
    },
    {
      "activeForm": "Creating network connectivity monitor",
      "content": "Create network connectivity monitor service",
      "status": "completed"
    },
    {
      "activeForm": "Adding WiFi-only setting persistence",
      "content": "Add WiFi-only setting persistence (SharedPreferences)",
      "status": "completed"
    },
    {
      "activeForm": "Integrating network monitor with downloads",
      "content": "Integrate network monitor with download queue manager",
      "status": "completed"
    },
    {
      "activeForm": "Adding WiFi-only toggle UI",
      "content": "Add WiFi-only toggle UI in download queue screen",
      "status": "completed"
    },
    {
      "activeForm": "Testing implementation",
      "content": "Test and verify the implementation compiles",
      "status": "in_progress"
    }
  ]
}

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\" && flutter pub get",
  "description": "Install Flutter dependencies including connectivity_plus and shared_preferences",
  "timeout": 120000
}
Dependencies installed. Now let me verify the code compiles.

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\" && flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1",
  "description": "Run Flutter static analysis to check for compile errors",
  "timeout": 120000
}
The analysis shows only 2 info-level issues (a deprecation warning and an async gap warning), neither of which are errors. The code compiles successfully.

Let me also quickly check the `download_record.dart` to see if the linter-added `thumbnailUrl` field is properly defined there (since the linter added it to the download record in the queue manager).

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_record.dart"
}
Good - the `thumbnailUrl` field is already in `DownloadRecord`. The linter change was consistent.

Let me also fix the deprecation warning in our new code while I'm at it.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_screen.dart",
  "old_string": "                  child: Switch(\n                    value: networkMonitor.wifiOnlyEnabled,\n                    onChanged: (val) => networkMonitor.setWifiOnly(val),\n                    activeColor: Colors.green,\n                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,",
  "new_string": "                  child: Switch(\n                    value: networkMonitor.wifiOnlyEnabled,\n                    onChanged: (val) => networkMonitor.setWifiOnly(val),\n                    activeTrackColor: Colors.green,\n                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,"
}

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\" && flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1",
  "description": "Verify no new analysis issues after fix",
  "timeout": 60000
}
Only the pre-existing issue in `share_service.dart` remains (not related to our changes). Let me verify the final state of all modified files.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 60,
  "offset": 78
}
Let me also verify the `_processQueue` WiFi check and the WiFi pause/resume methods.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 50,
  "offset": 290
}

🔧 Tool: Grep
Input: {
  "pattern": "_pauseForWifi|_resumeAfterWifi|isWifiPaused",
  "path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "output_mode": "content",
  "-n": true
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 30,
  "offset": 735
}
Everything looks correct. Let me mark the task as complete.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and understand existing download system",
      "status": "completed"
    },
    {
      "activeForm": "Adding connectivity_plus dependency",
      "content": "Add connectivity_plus dependency to pubspec.yaml",
      "status": "completed"
    },
    {
      "activeForm": "Creating network connectivity monitor",
      "content": "Create network connectivity monitor service",
      "status": "completed"
    },
    {
      "activeForm": "Adding WiFi-only setting persistence",
      "content": "Add WiFi-only setting persistence (SharedPreferences)",
      "status": "completed"
    },
    {
      "activeForm": "Integrating network monitor with downloads",
      "content": "Integrate network monitor with download queue manager",
      "status": "completed"
    },
    {
      "activeForm": "Adding WiFi-only toggle UI",
      "content": "Add WiFi-only toggle UI in download queue screen",
      "status": "completed"
    },
    {
      "activeForm": "Testing implementation",
      "content": "Test and verify the implementation compiles",
      "status": "completed"
    }
  ]
}
<summary>
## Summary: WiFi-Only Download Mode

### Changes Implemented
- Added `connectivity_plus` and `shared_preferences` dependencies for network state monitoring and settings persistence
- Created a `NetworkMonitor` service that listens for connectivity changes and exposes WiFi-only toggle with persistent storage
- Integrated network monitor into `DownloadQueueManager` — pauses active downloads on WiFi disconnect, auto-resumes on WiFi reconnect
- `_processQueue` now checks WiFi status before starting new downloads when WiFi-only mode is enabled
- Added WiFi-paused item tracking (`_wifiPausedItems` set) to distinguish system-paused vs user-paused items
- Added WiFi-only toggle UI in the download queue screen summary bar with status indicator (connected/waiting/paused count)

### Files Modified
- `x_video_downloader_flutter_frontend/pubspec.yaml` — Added `connectivity_plus: ^6.1.4` and `shared_preferences: ^2.5.3`
- `x_video_downloader_flutter_frontend/lib/network_monitor.dart` — **New file**: Network connectivity monitor with WiFi-only setting persistence
- `x_video_downloader_flutter_frontend/lib/download_queue_manager.dart` — Added `networkMonitor` field, `_wifiPausedItems` tracking, `_pauseForWifi()`, `_resumeAfterWifi()`, `isWifiPaused()`, WiFi check in `_processQueue()`, and network monitor callback wiring in `init()`
- `x_video_downloader_flutter_frontend/lib/download_queue_screen.dart` — Added `NetworkMonitor` parameter, WiFi-only toggle row in summary bar with live status display
- `x_video_downloader_flutter_frontend/lib/main.dart` — Added global `NetworkMonitor` instance, initialization in `main()`, passed to queue manager and all `DownloadQueueScreen` navigations

### Notes for Developer
- The WiFi-only setting persists across app restarts via SharedPreferences
- Downloads paused by WiFi disconnect are tracked separately from user-paused downloads — only WiFi-paused items auto-resume when WiFi reconnects
- When WiFi-only is enabled and the device is not on WiFi, new downloads will not start (they remain queued)
- Flutter analyze passes with no errors (only 1 pre-existing info-level warning in unrelated file)
</summary>