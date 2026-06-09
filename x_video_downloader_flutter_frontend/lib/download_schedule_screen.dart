import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'download_record.dart';
import 'download_scheduler.dart';
import 'network_monitor.dart';
import 'scheduled_download.dart';

/// Screen for viewing and managing scheduled downloads.
class DownloadScheduleScreen extends StatefulWidget {
  final DownloadScheduler scheduler;
  final NetworkMonitor networkMonitor;

  const DownloadScheduleScreen({
    super.key,
    required this.scheduler,
    required this.networkMonitor,
  });

  @override
  State<DownloadScheduleScreen> createState() => _DownloadScheduleScreenState();
}

class _DownloadScheduleScreenState extends State<DownloadScheduleScreen> {
  @override
  void initState() {
    super.initState();
    widget.scheduler.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.scheduler.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final schedules = widget.scheduler.schedules;

    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled Downloads')),
      body:
          schedules.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No scheduled downloads',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to schedule a download for later',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return _ScheduleTile(
                    schedule: schedule,
                    onCancel: () => _confirmCancel(schedule),
                    onEdit: () => _showEditSheet(schedule),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleSheet,
        tooltip: 'Schedule download',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddScheduleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => _ScheduleFormSheet(
            networkMonitor: widget.networkMonitor,
            onSave: (schedule) async {
              await widget.scheduler.addSchedule(schedule);
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            },
          ),
    );
  }

  void _showEditSheet(ScheduledDownload schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => _ScheduleFormSheet(
            networkMonitor: widget.networkMonitor,
            existingSchedule: schedule,
            onSave: (updated) async {
              await widget.scheduler.updateSchedule(updated);
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            },
          ),
    );
  }

  void _confirmCancel(ScheduledDownload schedule) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cancel Schedule'),
            content: Text(
              'Cancel the scheduled download for "${schedule.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.scheduler.cancelSchedule(schedule.id!);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Cancel Schedule'),
              ),
            ],
          ),
    );
  }
}

/// A single scheduled download tile.
class _ScheduleTile extends StatelessWidget {
  final ScheduledDownload schedule;
  final VoidCallback onCancel;
  final VoidCallback onEdit;

  const _ScheduleTile({
    required this.schedule,
    required this.onCancel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d, yyyy');
    final nextExec = schedule.nextExecution;

    Color statusColor;
    IconData statusIcon;
    switch (schedule.status) {
      case ScheduledDownloadStatus.scheduled:
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case ScheduledDownloadStatus.executing:
        statusColor = Colors.orange;
        statusIcon = Icons.downloading;
        break;
      case ScheduledDownloadStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ScheduledDownloadStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
      case ScheduledDownloadStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(statusIcon, size: 20, color: statusColor),
      ),
      title: Text(
        schedule.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                nextExec != null
                    ? '${dateFormat.format(nextExec)} at ${timeFormat.format(nextExec)}'
                    : 'No upcoming execution',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.repeat, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                schedule.recurrenceLabel,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              if (schedule.wifiOnly) ...[
                const SizedBox(width: 8),
                Icon(Icons.wifi, size: 14, color: Colors.green[600]),
                const SizedBox(width: 2),
                Text(
                  'WiFi only',
                  style: TextStyle(fontSize: 11, color: Colors.green[600]),
                ),
              ],
              if (schedule.formatLabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  schedule.formatLabel!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
              const Spacer(),
              if (schedule.executionCount > 0)
                Text(
                  'Run ${schedule.executionCount}x',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
            ],
          ),
          if (schedule.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                schedule.errorMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.red[300]),
              ),
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'cancel') onCancel();
          if (value == 'edit') onEdit();
        },
        itemBuilder:
            (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'cancel',
                child: Text(
                  'Cancel Schedule',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
      ),
    );
  }
}

/// Bottom sheet form for creating or editing a scheduled download.
class _ScheduleFormSheet extends StatefulWidget {
  final NetworkMonitor networkMonitor;
  final ScheduledDownload? existingSchedule;
  final Future<void> Function(ScheduledDownload) onSave;

  const _ScheduleFormSheet({
    required this.networkMonitor,
    this.existingSchedule,
    required this.onSave,
  });

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  late TimeOfDay _selectedTime;
  late DateTime _selectedDate;
  late ScheduleRecurrence _recurrence;
  late bool _wifiOnly;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingSchedule;
    if (existing != null) {
      _urlController.text = existing.url;
      _titleController.text = existing.title;
      _selectedTime = TimeOfDay.fromDateTime(existing.scheduledTime);
      _selectedDate = DateTime(
        existing.scheduledTime.year,
        existing.scheduledTime.month,
        existing.scheduledTime.day,
      );
      _recurrence = existing.recurrence;
      _wifiOnly = existing.wifiOnly;
    } else {
      // Default: tomorrow at 2:00 AM
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      _selectedTime = const TimeOfDay(hour: 2, minute: 0);
      _recurrence = ScheduleRecurrence.once;
      _wifiOnly = false;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSchedule != null;
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d, yyyy');

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            isEditing ? 'Edit Scheduled Download' : 'Schedule a Download',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // URL field
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Video URL',
              border: OutlineInputBorder(),
              hintText: 'Paste a video URL to download',
            ),
            enabled: !isEditing,
          ),
          const SizedBox(height: 12),

          // Title field
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title (optional)',
              border: OutlineInputBorder(),
              hintText: 'Auto-detected from URL',
            ),
          ),
          const SizedBox(height: 16),

          // Date & Time pickers
          Text(
            'Schedule Time',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(dateFormat.format(_selectedDate)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(timeFormat.format(scheduledDateTime)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recurrence selector
          Text(
            'Repeat',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                ScheduleRecurrence.values.map((r) {
                  final selected = r == _recurrence;
                  return ChoiceChip(
                    label: Text(
                      r == ScheduleRecurrence.once
                          ? 'One-time'
                          : r == ScheduleRecurrence.weekdays
                          ? 'Weekdays'
                          : r == ScheduleRecurrence.weekends
                          ? 'Weekends'
                          : r.name[0].toUpperCase() + r.name.substring(1),
                    ),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _recurrence = r);
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),

          // WiFi-only toggle
          SwitchListTile(
            value: _wifiOnly,
            onChanged: (val) => setState(() => _wifiOnly = val),
            title: const Text('WiFi only'),
            subtitle: Text(
              _wifiOnly
                  ? 'Will only download when connected to WiFi'
                  : 'Downloads on any network',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            secondary: Icon(
              _wifiOnly ? Icons.wifi : Icons.wifi_off,
              color: _wifiOnly ? Colors.green : Colors.grey,
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon:
                  _isSaving
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.schedule),
              label: Text(isEditing ? 'Update Schedule' : 'Schedule Download'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a video URL')));
      return;
    }

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheduled time must be in the future')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final title =
        _titleController.text.trim().isEmpty
            ? 'Scheduled download'
            : _titleController.text.trim();

    final schedule = ScheduledDownload(
      id: widget.existingSchedule?.id,
      url: url,
      platform: DownloadRecord.detectPlatform(url),
      title: title,
      thumbnailUrl: widget.existingSchedule?.thumbnailUrl,
      scheduledTime: scheduledDateTime,
      recurrence: _recurrence,
      wifiOnly: _wifiOnly,
      formatId: widget.existingSchedule?.formatId,
      formatLabel: widget.existingSchedule?.formatLabel,
      status:
          widget.existingSchedule?.status ?? ScheduledDownloadStatus.scheduled,
      createdAt: widget.existingSchedule?.createdAt ?? DateTime.now(),
      lastExecutedAt: widget.existingSchedule?.lastExecutedAt,
      executionCount: widget.existingSchedule?.executionCount ?? 0,
    );

    await widget.onSave(schedule);

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
