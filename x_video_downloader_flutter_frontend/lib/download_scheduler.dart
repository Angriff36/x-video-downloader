import 'dart:async';

import 'package:flutter/foundation.dart';

import 'download_database.dart';
import 'download_queue_manager.dart';
import 'network_monitor.dart';
import 'scheduled_download.dart';

/// Service that manages scheduled downloads by periodically checking for
/// due schedules and submitting them to the download queue.
///
/// Uses a periodic timer that checks every minute for scheduled downloads
/// whose execution time has arrived. Supports WiFi-only constraints and
/// automatic recurrence handling.
class DownloadScheduler extends ChangeNotifier {
  final DownloadDatabase _db = DownloadDatabase();
  DownloadQueueManager? queueManager;
  NetworkMonitor? networkMonitor;

  /// In-memory list of active scheduled downloads.
  final List<ScheduledDownload> _schedules = [];
  List<ScheduledDownload> get schedules => List.unmodifiable(_schedules);

  /// Timer that fires every minute to check for due schedules.
  Timer? _checkTimer;

  bool _initialized = false;

  /// Initialize the scheduler: load persisted schedules and start the timer.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final items = await _db.getActiveScheduledDownloads();
    _schedules.addAll(items);

    // Check immediately on startup for any schedules that were due while
    // the app was closed.
    await _checkAndExecuteDue();

    // Start periodic check — every 60 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkAndExecuteDue();
    });

    notifyListeners();
  }

  /// Add a new scheduled download.
  Future<ScheduledDownload> addSchedule(ScheduledDownload schedule) async {
    final id = await _db.insertScheduledDownload(schedule);
    final saved = schedule.copyWith(id: id);
    _schedules.add(saved);
    notifyListeners();
    return saved;
  }

  /// Cancel a scheduled download.
  Future<void> cancelSchedule(int scheduleId) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index == -1) return;

    _schedules[index] = _schedules[index].copyWith(
      status: ScheduledDownloadStatus.cancelled,
    );
    await _db.updateScheduledDownload(_schedules[index]);
    _schedules.removeAt(index);
    notifyListeners();
  }

  /// Update an existing scheduled download.
  Future<void> updateSchedule(ScheduledDownload schedule) async {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index == -1) return;

    _schedules[index] = schedule;
    await _db.updateScheduledDownload(schedule);
    notifyListeners();
  }

  /// Delete a scheduled download (regardless of status).
  Future<void> deleteSchedule(int scheduleId) async {
    _schedules.removeWhere((s) => s.id == scheduleId);
    await _db.deleteScheduledDownload(scheduleId);
    notifyListeners();
  }

  /// Check for schedules that are due and execute them.
  Future<void> _checkAndExecuteDue() async {
    if (queueManager == null) return;

    final now = DateTime.now();
    final toExecute = <ScheduledDownload>[];

    for (int i = 0; i < _schedules.length; i++) {
      final schedule = _schedules[i];
      if (schedule.status != ScheduledDownloadStatus.scheduled) continue;

      final nextTime = schedule.nextExecution;
      if (nextTime != null && !nextTime.isAfter(now)) {
        // Check WiFi constraint
        if (schedule.wifiOnly &&
            networkMonitor != null &&
            !networkMonitor!.isOnWifi) {
          continue; // Skip — not on WiFi
        }
        toExecute.add(schedule);
      }
    }

    for (final schedule in toExecute) {
      await _executeSchedule(schedule);
    }
  }

  /// Execute a single scheduled download by adding it to the queue.
  Future<void> _executeSchedule(ScheduledDownload schedule) async {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index == -1) return;

    try {
      // Mark as executing
      _schedules[index] = schedule.copyWith(
        status: ScheduledDownloadStatus.executing,
      );
      await _db.updateScheduledDownload(_schedules[index]);
      notifyListeners();

      // Add to the download queue
      await queueManager!.addToQueue(
        url: schedule.url,
        title: schedule.title,
        thumbnailUrl: schedule.thumbnailUrl,
        formatId: schedule.formatId,
        formatLabel: schedule.formatLabel,
      );

      // Handle recurrence
      if (schedule.recurrence == ScheduleRecurrence.once) {
        // One-time schedule — mark completed and remove
        _schedules[index] = _schedules[index].copyWith(
          status: ScheduledDownloadStatus.completed,
          lastExecutedAt: DateTime.now(),
          executionCount: _schedules[index].executionCount + 1,
        );
        await _db.updateScheduledDownload(_schedules[index]);
        _schedules.removeAt(index);
      } else {
        // Recurring schedule — update last execution and keep active
        _schedules[index] = _schedules[index].copyWith(
          lastExecutedAt: DateTime.now(),
          executionCount: _schedules[index].executionCount + 1,
        );
        await _db.updateScheduledDownload(_schedules[index]);

        // Advance scheduledTime for next occurrence
        final nextTime = _schedules[index].nextExecution;
        if (nextTime != null) {
          _schedules[index] = _schedules[index].copyWith(
            scheduledTime: nextTime,
          );
          await _db.updateScheduledDownload(_schedules[index]);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Scheduled download execution failed: $e');

      final idx = _schedules.indexWhere((s) => s.id == schedule.id);
      if (idx != -1) {
        _schedules[idx] = _schedules[idx].copyWith(
          status: ScheduledDownloadStatus.error,
          errorMessage: e.toString(),
        );
        await _db.updateScheduledDownload(_schedules[idx]);
        notifyListeners();
      }
    }
  }

  /// Get the number of active (scheduled) downloads.
  int get activeCount =>
      _schedules.where((s) => s.status == ScheduledDownloadStatus.scheduled).length;

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
