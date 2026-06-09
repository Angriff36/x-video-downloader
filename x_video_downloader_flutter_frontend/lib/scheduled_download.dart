/// Represents a scheduled download that will execute at a specified time.
///
/// Supports one-time and recurring schedules with optional WiFi-only constraint.
class ScheduledDownload {
  final int? id;
  final String url;
  final String platform;
  final String title;
  final String? thumbnailUrl;

  // Schedule configuration
  final DateTime scheduledTime;
  final ScheduleRecurrence recurrence;
  final bool wifiOnly;

  // Format selection (optional — null means best quality)
  final String? formatId;
  final String? formatLabel;

  // Status tracking
  final ScheduledDownloadStatus status;
  final DateTime createdAt;
  final DateTime? lastExecutedAt;
  final int executionCount;
  final String? errorMessage;

  ScheduledDownload({
    this.id,
    required this.url,
    required this.platform,
    required this.title,
    this.thumbnailUrl,
    required this.scheduledTime,
    this.recurrence = ScheduleRecurrence.once,
    this.wifiOnly = false,
    this.formatId,
    this.formatLabel,
    this.status = ScheduledDownloadStatus.scheduled,
    required this.createdAt,
    this.lastExecutedAt,
    this.executionCount = 0,
    this.errorMessage,
  });

  /// Human-readable description of the recurrence pattern.
  String get recurrenceLabel {
    switch (recurrence) {
      case ScheduleRecurrence.once:
        return 'One-time';
      case ScheduleRecurrence.daily:
        return 'Daily';
      case ScheduleRecurrence.weekdays:
        return 'Weekdays';
      case ScheduleRecurrence.weekends:
        return 'Weekends';
      case ScheduleRecurrence.weekly:
        return 'Weekly';
    }
  }

  /// The next execution time based on recurrence and last execution.
  DateTime? get nextExecution {
    if (status == ScheduledDownloadStatus.cancelled ||
        status == ScheduledDownloadStatus.error) {
      return null;
    }
    if (recurrence == ScheduleRecurrence.once) {
      return status == ScheduledDownloadStatus.scheduled
          ? scheduledTime
          : null;
    }
    if (lastExecutedAt == null) return scheduledTime;

    // Calculate next occurrence from last execution
    DateTime next;
    switch (recurrence) {
      case ScheduleRecurrence.daily:
        next = DateTime(
          lastExecutedAt!.year,
          lastExecutedAt!.month,
          lastExecutedAt!.day + 1,
          scheduledTime.hour,
          scheduledTime.minute,
        );
        break;
      case ScheduleRecurrence.weekdays:
        next = _nextWeekday(lastExecutedAt!);
        break;
      case ScheduleRecurrence.weekends:
        next = _nextWeekend(lastExecutedAt!);
        break;
      case ScheduleRecurrence.weekly:
        next = DateTime(
          lastExecutedAt!.year,
          lastExecutedAt!.month,
          lastExecutedAt!.day + 7,
          scheduledTime.hour,
          scheduledTime.minute,
        );
        break;
      default:
        return scheduledTime;
    }

    // If next is still in the past, advance day by day until future
    while (next.isBefore(DateTime.now())) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }

  DateTime _nextWeekday(DateTime from) {
    var next = DateTime(
      from.year,
      from.month,
      from.day + 1,
      scheduledTime.hour,
      scheduledTime.minute,
    );
    while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  DateTime _nextWeekend(DateTime from) {
    var next = DateTime(
      from.year,
      from.month,
      from.day + 1,
      scheduledTime.hour,
      scheduledTime.minute,
    );
    while (next.weekday != DateTime.saturday && next.weekday != DateTime.sunday) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  factory ScheduledDownload.fromMap(Map<String, dynamic> map) {
    return ScheduledDownload(
      id: map['id'] as int?,
      url: map['url'] as String,
      platform: map['platform'] as String,
      title: map['title'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduledTime'] as int),
      recurrence: ScheduleRecurrence.values.firstWhere(
        (r) => r.name == (map['recurrence'] as String),
        orElse: () => ScheduleRecurrence.once,
      ),
      wifiOnly: (map['wifiOnly'] as int?) == 1,
      formatId: map['formatId'] as String?,
      formatLabel: map['formatLabel'] as String?,
      status: ScheduledDownloadStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String),
        orElse: () => ScheduledDownloadStatus.scheduled,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      lastExecutedAt: map['lastExecutedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastExecutedAt'] as int)
          : null,
      executionCount: (map['executionCount'] as num?)?.toInt() ?? 0,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'url': url,
      'platform': platform,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'recurrence': recurrence.name,
      'wifiOnly': wifiOnly ? 1 : 0,
      'formatId': formatId,
      'formatLabel': formatLabel,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastExecutedAt': lastExecutedAt?.millisecondsSinceEpoch,
      'executionCount': executionCount,
      'errorMessage': errorMessage,
    };
  }

  ScheduledDownload copyWith({
    int? id,
    String? url,
    String? platform,
    String? title,
    String? thumbnailUrl,
    DateTime? scheduledTime,
    ScheduleRecurrence? recurrence,
    bool? wifiOnly,
    String? formatId,
    String? formatLabel,
    ScheduledDownloadStatus? status,
    DateTime? createdAt,
    DateTime? lastExecutedAt,
    int? executionCount,
    String? errorMessage,
  }) {
    return ScheduledDownload(
      id: id ?? this.id,
      url: url ?? this.url,
      platform: platform ?? this.platform,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      recurrence: recurrence ?? this.recurrence,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      formatId: formatId ?? this.formatId,
      formatLabel: formatLabel ?? this.formatLabel,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      executionCount: executionCount ?? this.executionCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// How often a scheduled download recurs.
enum ScheduleRecurrence {
  once,
  daily,
  weekdays,
  weekends,
  weekly,
}

/// Status of a scheduled download.
enum ScheduledDownloadStatus {
  scheduled,
  executing,
  completed,
  cancelled,
  error,
}
