import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'storage_service.dart';

/// Screen for viewing storage usage, breakdown, and managing cleanup.
class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  State<StorageManagementScreen> createState() => _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  final StorageService _storageService = StorageService();

  StorageSummary? _summary;
  bool _isLoading = true;
  bool _isCleaning = false;
  CleanupRule _cleanupRule = CleanupRule.disabled;
  bool _cleanupFailed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _storageService.getStorageSummary(),
        _storageService.getCleanupRule(),
        _storageService.getCleanupFailedEnabled(),
      ]);
      if (mounted) {
        setState(() {
          _summary = results[0] as StorageSummary;
          _cleanupRule = results[1] as CleanupRule;
          _cleanupFailed = results[2] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading storage info: $e')),
        );
      }
    }
  }

  Future<void> _performCleanup(Future<CleanupResult> Function() action) async {
    setState(() => _isCleaning = true);
    try {
      final result = await action();
      if (mounted) {
        final msg = StringBuffer();
        msg.write('Cleaned up ${result.filesDeleted} item${result.filesDeleted != 1 ? 's' : ''}');
        if (result.bytesFreed > 0) {
          msg.write(', freed ${StorageService.formatBytes(result.bytesFreed)}');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.toString())),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleanup error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCleaning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Icon(Icons.warning_amber_rounded, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Could not load storage information.',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOverviewCard(theme, colorScheme),
                  const SizedBox(height: 16),
                  _buildPlatformBreakdownCard(theme, colorScheme),
                  const SizedBox(height: 16),
                  _buildLargestFilesCard(theme, colorScheme),
                  const SizedBox(height: 16),
                  _buildCleanupActionsCard(theme, colorScheme),
                  const SizedBox(height: 16),
                  _buildAutoCleanupCard(theme, colorScheme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCard(ThemeData theme, ColorScheme colorScheme) {
    final summary = _summary!;
    final total = summary.totalUsedBytes;
    final completedPct = total > 0 ? summary.completedBytes / total : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Storage Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Total usage
            Center(
              child: Column(
                children: [
                  Text(
                    StorageService.formatBytes(total),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total space used by downloads',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Usage bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 12,
                child: LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completedPct > 0
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  '${summary.completedCount}',
                  'Completed',
                  colorScheme.primary,
                  Icons.check_circle_outline,
                ),
                _buildStatColumn(
                  '${summary.failedCount}',
                  'Failed',
                  colorScheme.error,
                  Icons.error_outline,
                ),
                _buildStatColumn(
                  '${summary.deletedCount}',
                  'Deleted',
                  colorScheme.onSurfaceVariant,
                  Icons.delete_outline,
                ),
                _buildStatColumn(
                  '${summary.filesOnDisk}',
                  'On Disk',
                  colorScheme.tertiary,
                  Icons.folder_outlined,
                ),
              ],
            ),
            if (summary.orphanedBytes > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 18, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${StorageService.formatBytes(summary.orphanedBytes)} in orphaned records (files no longer on disk)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  Widget _buildPlatformBreakdownCard(ThemeData theme, ColorScheme colorScheme) {
    final breakdown = _summary!.platformBreakdown;
    if (breakdown.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Platform Breakdown',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(child: Text('No downloads yet')),
            ],
          ),
        ),
      );
    }

    final totalBytes = breakdown.fold(0, (sum, p) => sum + p.totalBytes);
    final colors = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      colorScheme.error,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Platform Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Pie chart
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: breakdown.asMap().entries.map((entry) {
                          final index = entry.key;
                          final info = entry.value;
                          final pct = totalBytes > 0
                              ? (info.totalBytes / totalBytes) * 100
                              : 0.0;
                          return PieChartSectionData(
                            value: info.totalBytes.toDouble(),
                            title: pct >= 5
                                ? '${pct.toStringAsFixed(0)}%'
                                : '',
                            color: colors[index % colors.length],
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Legend
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: breakdown.asMap().entries.map((entry) {
                        final index = entry.key;
                        final info = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  info.platform,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            // Detail list
            ...breakdown.asMap().entries.map((entry) {
              final index = entry.key;
              final info = entry.value;
              final pct = totalBytes > 0
                  ? (info.totalBytes / totalBytes) * 100
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                info.platform,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                StorageService.formatBytes(info.totalBytes),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colors[index % colors.length],
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${info.completedCount} completed, ${info.fileCount} total',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLargestFilesCard(ThemeData theme, ColorScheme colorScheme) {
    final files = _summary!.largestFiles;
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sort, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Largest Files',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...files.take(10).map((file) => _buildFileTile(file, theme, colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTile(LargeFileInfo file, ThemeData theme, ColorScheme colorScheme) {
    final age = DateTime.now().difference(file.downloadedAt);
    String ageText;
    if (age.inDays == 0) {
      ageText = 'Today';
    } else if (age.inDays == 1) {
      ageText = 'Yesterday';
    } else if (age.inDays < 30) {
      ageText = '${age.inDays} days ago';
    } else if (age.inDays < 365) {
      ageText = '${(age.inDays / 30).floor()} months ago';
    } else {
      ageText = '${(age.inDays / 365).floor()} years ago';
    }

    return Dismissible(
      key: ValueKey(file.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),
      confirmDismiss: (direction) async {
        return showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Download'),
            content: Text(
              'Delete "${file.title}"? This will remove the file from your device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await _performCleanup(
          () => _storageService.deleteFiles([file.id]),
        );
      },
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(
          file.status == 'completed' ? Icons.videocam : Icons.error_outline,
          color: file.status == 'completed' ? colorScheme.primary : colorScheme.error,
          size: 20,
        ),
        title: Text(
          file.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: Text(
          '${file.platform} · $ageText',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            StorageService.formatBytes(file.fileSizeBytes),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanupActionsCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cleaning_services, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'One-Tap Cleanup',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Cleanup options
            _buildCleanupOption(
              icon: Icons.error_outline,
              title: 'Remove Failed Downloads',
              subtitle: 'Clear all failed download records',
              color: colorScheme.error,
              onTap: _isCleaning
                  ? null
                  : () => _performCleanup(
                        () => _storageService.cleanupFailedDownloads(),
                      ),
            ),
            const SizedBox(height: 8),
            _buildCleanupOption(
              icon: Icons.folder_off_outlined,
              title: 'Remove Orphaned Records',
              subtitle: 'Clean up records for files no longer on disk',
              color: colorScheme.tertiary,
              onTap: _isCleaning
                  ? null
                  : () => _performCleanup(
                        () => _storageService.cleanupOrphanedRecords(),
                      ),
            ),
            const SizedBox(height: 8),
            _buildCleanupOption(
              icon: Icons.schedule_outlined,
              title: 'Remove Downloads Older Than 30 Days',
              subtitle: 'Delete completed downloads from over 30 days ago',
              color: colorScheme.secondary,
              onTap: _isCleaning
                  ? null
                  : () => _performCleanup(
                        () => _storageService.cleanupOldDownloads(30),
                      ),
            ),
            const SizedBox(height: 8),
            _buildCleanupOption(
              icon: Icons.delete_sweep_outlined,
              title: 'Remove All Downloads',
              subtitle: 'Delete all downloaded files and records',
              color: colorScheme.error,
              onTap: _isCleaning ? null : () => _showDeleteAllConfirmation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanupOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            if (_isCleaning)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoCleanupCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_delete_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Auto-Cleanup Rules',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Cleanup rule selector
            Text(
              'Automatically delete completed downloads:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CleanupRule.values.map((rule) {
                final isSelected = _cleanupRule == rule;
                return ChoiceChip(
                  label: Text(rule.label),
                  selected: isSelected,
                  onSelected: (selected) async {
                    if (selected) {
                      await _storageService.setCleanupRule(rule);
                      setState(() => _cleanupRule = rule);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Auto-cleanup failed downloads toggle
            SwitchListTile(
              value: _cleanupFailed,
              onChanged: (value) async {
                await _storageService.setCleanupFailedEnabled(value);
                setState(() => _cleanupFailed = value);
              },
              title: const Text('Auto-remove failed downloads'),
              subtitle: const Text(
                'Automatically delete records for failed downloads',
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAllConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Downloads?'),
        content: const Text(
          'This will permanently delete all downloaded files and remove all '
          'download records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performCleanup(() async {
        // First delete old downloads (all of them)
        final result1 = await _storageService.cleanupOldDownloads(0);
        // Then clean failed
        final result2 = await _storageService.cleanupFailedDownloads();
        // Then clean orphaned
        final result3 = await _storageService.cleanupOrphanedRecords();
        return CleanupResult(
          filesDeleted: result1.filesDeleted + result2.filesDeleted + result3.filesDeleted,
          bytesFreed: result1.bytesFreed + result2.bytesFreed + result3.bytesFreed,
          errors: [...result1.errors, ...result2.errors, ...result3.errors],
        );
      });
    }
  }
}
