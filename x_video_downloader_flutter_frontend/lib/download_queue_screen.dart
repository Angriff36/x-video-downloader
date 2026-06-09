import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'download_queue_manager.dart';
import 'network_monitor.dart';
import 'queue_item.dart';

/// Screen showing the download queue with pause/resume/retry controls.
class DownloadQueueScreen extends StatefulWidget {
  final DownloadQueueManager queueManager;
  final NetworkMonitor networkMonitor;

  const DownloadQueueScreen({
    super.key,
    required this.queueManager,
    required this.networkMonitor,
  });

  @override
  State<DownloadQueueScreen> createState() => _DownloadQueueScreenState();
}

class _DownloadQueueScreenState extends State<DownloadQueueScreen> {
  @override
  void initState() {
    super.initState();
    widget.queueManager.addListener(_onQueueChanged);
    widget.networkMonitor.addListener(_onQueueChanged);
  }

  @override
  void dispose() {
    widget.queueManager.removeListener(_onQueueChanged);
    widget.networkMonitor.removeListener(_onQueueChanged);
    super.dispose();
  }

  void _onQueueChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final queue = widget.queueManager.queue;
    final activeItems =
        queue.where((i) => i.status == QueueItemStatus.downloading).toList();
    final pausedItems =
        queue.where((i) => i.status == QueueItemStatus.paused).toList();
    final queuedItems =
        queue.where((i) => i.status == QueueItemStatus.queued).toList();
    final completedItems =
        queue.where((i) => i.status == QueueItemStatus.completed).toList();
    final failedItems =
        queue.where((i) => i.status == QueueItemStatus.failed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Queue'),
        actions: [
          if (widget.queueManager.activeCount > 0)
            IconButton(
              icon: const Icon(Icons.pause_circle),
              tooltip: 'Pause all',
              onPressed: () => widget.queueManager.pauseAll(),
            )
          else if (widget.queueManager.queue.any(
              (i) => i.status == QueueItemStatus.paused))
            IconButton(
              icon: const Icon(Icons.play_circle),
              tooltip: 'Resume all',
              onPressed: () => widget.queueManager.resumeAll(),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_finished') {
                widget.queueManager.clearFinished();
              } else if (value == 'cancel_all') {
                _confirmCancelAll();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'clear_finished',
                child: Text('Clear Finished'),
              ),
              const PopupMenuItem(
                value: 'cancel_all',
                child: Text('Cancel All'),
              ),
            ],
          ),
        ],
      ),
      body: queue.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No downloads in queue',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Summary bar
                _SummaryBar(
                  active: activeItems.length,
                  queued: queuedItems.length,
                  completed: completedItems.length,
                  failed: failedItems.length,
                  maxConcurrent: widget.queueManager.maxConcurrent,
                  onMaxConcurrentChanged: (v) =>
                      widget.queueManager.maxConcurrent = v,
                  networkMonitor: widget.networkMonitor,
                  wifiPausedCount: widget.queueManager.queue
                      .where((i) =>
                          i.status == QueueItemStatus.paused &&
                          i.id != null &&
                          widget.queueManager.isWifiPaused(i.id!))
                      .length,
                ),
                const Divider(height: 1),

                // Active downloads
                if (activeItems.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Downloading',
                    count: activeItems.length,
                    icon: Icons.downloading,
                    color: Colors.blue,
                  ),
                  ...activeItems.map((item) => _QueueItemTile(
                        item: item,
                        onPause: () =>
                            widget.queueManager.pauseItem(item.id!),
                        onCancel: () =>
                            widget.queueManager.cancelItem(item.id!),
                      )),
                ],

                // Paused downloads
                if (pausedItems.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Paused',
                    count: pausedItems.length,
                    icon: Icons.pause_circle,
                    color: Colors.orange,
                  ),
                  ...pausedItems.map((item) => _QueueItemTile(
                        item: item,
                        onResume: () =>
                            widget.queueManager.resumeItem(item.id!),
                        onCancel: () =>
                            widget.queueManager.cancelItem(item.id!),
                      )),
                ],

                // Queued downloads
                if (queuedItems.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Queued',
                    count: queuedItems.length,
                    icon: Icons.schedule,
                    color: Colors.grey,
                  ),
                  ...queuedItems.map((item) => _QueueItemTile(
                        item: item,
                        onCancel: () =>
                            widget.queueManager.cancelItem(item.id!),
                      )),
                ],

                // Failed downloads
                if (failedItems.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Failed',
                    count: failedItems.length,
                    icon: Icons.error,
                    color: Colors.red,
                  ),
                  ...failedItems.map((item) => _QueueItemTile(
                        item: item,
                        onRetry: item.canRetry
                            ? () =>
                                widget.queueManager.retryItem(item.id!)
                            : null,
                        onRemove: () =>
                            widget.queueManager.removeItem(item.id!),
                      )),
                ],

                // Completed downloads
                if (completedItems.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Completed',
                    count: completedItems.length,
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  ...completedItems.map((item) => _QueueItemTile(
                        item: item,
                        onRemove: () =>
                            widget.queueManager.removeItem(item.id!),
                      )),
                ],
              ],
            ),
    );
  }

  void _confirmCancelAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel All Downloads'),
        content: const Text(
          'This will cancel all active and queued downloads. Paused downloads will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Downloads'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final items = widget.queueManager.queue
                  .where((i) =>
                      i.status == QueueItemStatus.downloading ||
                      i.status == QueueItemStatus.queued)
                  .toList();
              for (final item in items) {
                widget.queueManager.cancelItem(item.id!);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel All'),
          ),
        ],
      ),
    );
  }
}

/// Summary bar showing queue stats, WiFi-only toggle, and concurrent download setting.
class _SummaryBar extends StatelessWidget {
  final int active;
  final int queued;
  final int completed;
  final int failed;
  final int maxConcurrent;
  final ValueChanged<int> onMaxConcurrentChanged;
  final NetworkMonitor networkMonitor;
  final int wifiPausedCount;

  const _SummaryBar({
    required this.active,
    required this.queued,
    required this.completed,
    required this.failed,
    required this.maxConcurrent,
    required this.onMaxConcurrentChanged,
    required this.networkMonitor,
    required this.wifiPausedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              _StatChip(label: 'Active', count: active, color: Colors.blue),
              const SizedBox(width: 8),
              _StatChip(label: 'Queued', count: queued, color: Colors.grey),
              const SizedBox(width: 8),
              _StatChip(label: 'Done', count: completed, color: Colors.green),
              const SizedBox(width: 8),
              _StatChip(label: 'Failed', count: failed, color: Colors.red),
              const Spacer(),
              // Concurrent download selector
              InkWell(
                onTap: () => _showConcurrentPicker(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.settings, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$maxConcurrent concurrent',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // WiFi-only toggle row
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                networkMonitor.wifiOnlyEnabled ? Icons.wifi : Icons.wifi_off,
                size: 16,
                color: networkMonitor.wifiOnlyEnabled
                    ? (networkMonitor.isOnWifi ? Colors.green : Colors.orange)
                    : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  networkMonitor.wifiOnlyEnabled
                      ? (networkMonitor.isOnWifi
                          ? 'WiFi only — connected'
                          : 'WiFi only — waiting for WiFi ($wifiPausedCount paused)')
                      : 'WiFi only mode',
                  style: TextStyle(
                    fontSize: 12,
                    color: networkMonitor.wifiOnlyEnabled
                        ? (networkMonitor.isOnWifi ? Colors.green[700] : Colors.orange[700])
                        : Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(
                height: 28,
                child: FittedBox(
                  child: Switch(
                    value: networkMonitor.wifiOnlyEnabled,
                    onChanged: (val) => networkMonitor.setWifiOnly(val),
                    activeTrackColor: Colors.green,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConcurrentPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Max Concurrent Downloads',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3, 4, 5].map((n) {
                  final selected = n == maxConcurrent;
                  return ChoiceChip(
                    label: Text('$n'),
                    selected: selected,
                    onSelected: (_) {
                      onMaxConcurrentChanged(n);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Section header for grouping queue items.
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single queue item row with action buttons.
class _QueueItemTile extends StatelessWidget {
  final QueueItem item;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final VoidCallback? onRemove;

  const _QueueItemTile({
    required this.item,
    this.onPause,
    this.onResume,
    this.onRetry,
    this.onCancel,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (onCancel != null) {
          onCancel!();
        } else if (onRemove != null) {
          onRemove!();
        }
        return false;
      },
      child: ListTile(
        dense: true,
        leading: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      item.thumbnailUrl!,
                      width: 64,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _StatusIcon(status: item.status),
                    ),
                    if (item.status == QueueItemStatus.downloading)
                      Container(
                        width: 64,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${(item.progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : _StatusIcon(status: item.status),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  decoration: item.status == QueueItemStatus.cancelled
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            if (item.status == QueueItemStatus.failed && item.canRetry)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Retry ${item.retryCount}/${item.maxRetries}',
                  style: TextStyle(fontSize: 10, color: Colors.orange[700]),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            // Progress bar for active downloads
            if (item.status == QueueItemStatus.downloading)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: LinearProgressIndicator(
                  value: item.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            if (item.status == QueueItemStatus.paused)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: LinearProgressIndicator(
                  value: item.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.orange[300]!),
                ),
              ),
            Row(
              children: [
                Text(
                  item.platform,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                if (item.fileSizeBytes > 0 &&
                    item.status == QueueItemStatus.completed) ...[
                  const SizedBox(width: 6),
                  Text(
                    item.fileSizeText,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
                if (item.status == QueueItemStatus.downloading &&
                    item.progress > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${(item.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
                if (item.status == QueueItemStatus.downloading &&
                    item.speedBps > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    item.speedText,
                    style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                  ),
                ],
                if (item.status == QueueItemStatus.downloading &&
                    item.etaText.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    item.etaText,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
                const Spacer(),
                Text(
                  dateFormat.format(item.createdAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
            if (item.status == QueueItemStatus.failed &&
                item.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  item.errorMessage!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: item.retryable ? Colors.orange[600] : Colors.red[300],
                  ),
                ),
              ),
          ],
        ),
        trailing: _buildActions(),
      ),
    );
  }

  Widget? _buildActions() {
    final buttons = <Widget>[];

    if (onPause != null && item.status == QueueItemStatus.downloading) {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.pause, size: 20),
          onPressed: onPause,
          tooltip: 'Pause',
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    if (onResume != null && item.status == QueueItemStatus.paused) {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.play_arrow, size: 20),
          onPressed: onResume,
          tooltip: 'Resume',
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    if (onRetry != null && item.status == QueueItemStatus.failed) {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.refresh, size: 20, color: Colors.orange),
          onPressed: onRetry,
          tooltip: 'Retry',
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    if (buttons.isEmpty) return null;
    if (buttons.length == 1) return buttons.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: buttons,
    );
  }
}

/// Status icon for a queue item.
class _StatusIcon extends StatelessWidget {
  final QueueItemStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case QueueItemStatus.queued:
        icon = Icons.schedule;
        color = Colors.grey;
        break;
      case QueueItemStatus.downloading:
        icon = Icons.downloading;
        color = Colors.blue;
        break;
      case QueueItemStatus.paused:
        icon = Icons.pause_circle;
        color = Colors.orange;
        break;
      case QueueItemStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case QueueItemStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case QueueItemStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
