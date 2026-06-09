import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'download_record.dart';
import 'download_database.dart';
import 'share_service.dart';

/// Screen showing download history with search, filter, and management.
class DownloadHistoryScreen extends StatefulWidget {
  const DownloadHistoryScreen({super.key});

  @override
  State<DownloadHistoryScreen> createState() => _DownloadHistoryScreenState();
}

class _DownloadHistoryScreenState extends State<DownloadHistoryScreen> {
  final DownloadDatabase _db = DownloadDatabase();
  List<DownloadRecord> _records = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // 'all', 'completed', 'failed', 'deleted'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      List<DownloadRecord> records;
      if (_filterStatus == 'all') {
        records = await _db.getAllRecords();
      } else {
        records = await _db.getRecordsByStatus(_filterStatus);
      }
      if (_searchQuery.isNotEmpty) {
        records = records
            .where((r) =>
                r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                r.url.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecord(DownloadRecord record) async {
    // Delete the actual file if it exists
    if (record.filePath.isNotEmpty) {
      final file = File(record.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _db.deleteRecord(record.id!);
    _loadRecords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download removed')),
      );
    }
  }

  Future<void> _deleteFileOnly(DownloadRecord record) async {
    if (record.filePath.isNotEmpty) {
      final file = File(record.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _db.updateStatus(record.id!, 'deleted');
    _loadRecords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File deleted, record kept')),
      );
    }
  }

  void _confirmDelete(DownloadRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Remove "${record.title}" from history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteFileOnly(record);
            },
            child: const Text('Delete File Only'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteRecord(record);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _clearAllHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'This will remove all download records. Files on disk will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _db.deleteAllRecords();
              _loadRecords();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareRecord(DownloadRecord record) async {
    try {
      await ShareService.shareVideo(context, record);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download History'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _clearAllHistory();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear All History'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or URL...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _loadRecords();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadRecords();
              },
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filterStatus == 'all',
                    onTap: () {
                      setState(() => _filterStatus = 'all');
                      _loadRecords();
                    },
                  ),
                  _FilterChip(
                    label: 'Completed',
                    selected: _filterStatus == 'completed',
                    onTap: () {
                      setState(() => _filterStatus = 'completed');
                      _loadRecords();
                    },
                    color: Colors.green,
                  ),
                  _FilterChip(
                    label: 'Failed',
                    selected: _filterStatus == 'failed',
                    onTap: () {
                      setState(() => _filterStatus = 'failed');
                      _loadRecords();
                    },
                    color: Colors.red,
                  ),
                  _FilterChip(
                    label: 'Deleted',
                    selected: _filterStatus == 'deleted',
                    onTap: () {
                      setState(() => _filterStatus = 'deleted');
                      _loadRecords();
                    },
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          // Records list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No downloads found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          itemCount: _records.length,
                          itemBuilder: (ctx, i) =>
                              _HistoryItem(
                                record: _records[i],
                                onDelete: () => _confirmDelete(_records[i]),
                                onFileTap: () =>
                                    _openFileDetails(_records[i]),
                                onShare: () => _shareRecord(_records[i]),
                              ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _openFileDetails(DownloadRecord record) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _RecordDetailSheet(
        record: record,
        onDelete: () {
          Navigator.pop(ctx);
          _confirmDelete(record);
        },
        onShare: () {
          Navigator.pop(ctx);
          _shareRecord(record);
        },
      ),
    );
  }
}

/// A single history item in the list.
class _HistoryItem extends StatelessWidget {
  final DownloadRecord record;
  final VoidCallback onDelete;
  final VoidCallback onFileTap;
  final VoidCallback onShare;

  const _HistoryItem({
    required this.record,
    required this.onDelete,
    required this.onFileTap,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    IconData statusIcon;
    Color statusColor;
    switch (record.status) {
      case 'completed':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'failed':
        statusIcon = Icons.error;
        statusColor = Colors.red;
        break;
      case 'deleted':
        statusIcon = Icons.delete_outline;
        statusColor = Colors.grey;
        break;
      default:
        statusIcon = Icons.help_outline;
        statusColor = Colors.orange;
    }

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        onDelete();
        return false; // We handle deletion in the dialog
      },
      child: ListTile(
        leading: record.thumbnailUrl != null && record.thumbnailUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  record.thumbnailUrl!,
                  width: 64,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _PlatformIcon(platform: record.platform),
                ),
              )
            : _PlatformIcon(platform: record.platform),
        title: Text(
          record.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            decoration: record.status == 'deleted'
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  record.platform,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (record.fileSizeBytes > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    record.fileSizeText,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              dateFormat.format(record.downloadedAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (record.status == 'completed')
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share',
                onPressed: onShare,
              ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onFileTap,
            ),
          ],
        ),
        onTap: onFileTap,
      ),
    );
  }
}

/// Small platform icon/label.
class _PlatformIcon extends StatelessWidget {
  final String platform;
  const _PlatformIcon({required this.platform});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (platform) {
      case 'YouTube':
        icon = Icons.play_circle_filled;
        color = Colors.red;
        break;
      case 'Instagram':
        icon = Icons.camera_alt;
        color = Colors.purple;
        break;
      case 'TikTok':
        icon = Icons.music_note;
        color = Colors.black;
        break;
      case 'X/Twitter':
        icon = Icons.tag;
        color = Colors.blue;
        break;
      case 'Vimeo':
        icon = Icons.videocam;
        color = Colors.cyan;
        break;
      case 'Facebook':
        icon = Icons.facebook;
        color = Colors.blueAccent;
        break;
      default:
        icon = Icons.video_file;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// Filter chip widget.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.blue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: chipColor.withValues(alpha: 0.2),
        side: BorderSide(
          color: selected ? chipColor : Colors.grey[300]!,
        ),
      ),
    );
  }
}

/// Detail sheet for a download record.
class _RecordDetailSheet extends StatelessWidget {
  final DownloadRecord record;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _RecordDetailSheet({
    required this.record,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Thumbnail preview
                if (record.thumbnailUrl != null && record.thumbnailUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        record.thumbnailUrl!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Text(
                  record.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _DetailRow(label: 'Platform', value: record.platform),
                _DetailRow(
                  label: 'Status',
                  value: record.status.toUpperCase(),
                ),
                _DetailRow(
                  label: 'Date',
                  value: dateFormat.format(record.downloadedAt),
                ),
                _DetailRow(
                  label: 'File Size',
                  value: record.fileSizeText,
                ),
                _DetailRow(
                  label: 'URL',
                  value: record.url,
                ),
                if (record.errorMessage != null)
                  _DetailRow(
                    label: 'Error',
                    value: record.errorMessage!,
                    valueColor: Colors.red,
                  ),
                _DetailRow(
                  label: 'File Path',
                  value: record.filePath.isEmpty ? 'N/A' : record.filePath,
                ),
                const SizedBox(height: 20),
                if (record.status == 'completed' && record.filePath.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share),
                      label: const Text('Share Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (record.status == 'completed' && record.filePath.isNotEmpty)
                  const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
