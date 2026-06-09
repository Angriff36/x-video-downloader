import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'download_analytics.dart';
import 'analytics_service.dart';
import 'download_database.dart';

/// Screen showing download statistics and analytics with charts.
class DownloadAnalyticsScreen extends StatefulWidget {
  const DownloadAnalyticsScreen({super.key});

  @override
  State<DownloadAnalyticsScreen> createState() => _DownloadAnalyticsScreenState();
}

class _DownloadAnalyticsScreenState extends State<DownloadAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final DownloadDatabase _db = DownloadDatabase();

  DownloadAnalytics? _analytics;
  bool _isLoading = true;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final analytics = await _analyticsService.computeAnalytics(days: _selectedDays);
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final records = await _db.getAllRecordsForExport();
      if (records.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to export')),
          );
        }
        return;
      }

      // Export as JSON
      final jsonList = records.map((r) => {
        'title': r.title,
        'platform': r.platform,
        'status': r.status,
        'fileSizeBytes': r.fileSizeBytes,
        'url': r.url,
        'downloadedAt': r.downloadedAt.toIso8601String(),
        'errorMessage': r.errorMessage,
      }).toList();

      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonList);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/download_analytics_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      // Also create CSV
      final csvBuf = StringBuffer();
      csvBuf.writeln('Title,Platform,Status,FileSizeBytes,URL,DownloadedAt,ErrorMessage');
      for (final r in records) {
        csvBuf.writeln(
          '"${r.title.replaceAll('"', '""')}",'
          '${r.platform},'
          '${r.status},'
          '${r.fileSizeBytes},'
          '"${r.url}",'
          '${r.downloadedAt.toIso8601String()},'
          '"${(r.errorMessage ?? '').replaceAll('"', '""')}"',
        );
      }
      final csvFile = File('${dir.path}/download_analytics_${DateTime.now().millisecondsSinceEpoch}.csv');
      await csvFile.writeAsString(csvBuf.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Analytics exported'),
            action: SnackBarAction(
              label: 'Share CSV',
              onPressed: () {
                Share.shareXFiles(
                  [XFile(csvFile.path)],
                  subject: 'Download Analytics',
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Analytics'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportData();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Export Data'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? Center(
                  child: Text('Failed to load analytics',
                      style: TextStyle(color: colorScheme.error)),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _TimeRangeSelector(
                        selectedDays: _selectedDays,
                        onChanged: (days) {
                          setState(() => _selectedDays = days);
                          _loadAnalytics();
                        },
                      ),
                      const SizedBox(height: 16),
                      _OverviewCards(analytics: _analytics!),
                      const SizedBox(height: 20),
                      if (_analytics!.dailyCounts.isNotEmpty) ...[
                        _SectionTitle('Download Trends'),
                        const SizedBox(height: 8),
                        _DownloadTrendsChart(
                          dailyCounts: _analytics!.dailyCounts,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_analytics!.dailyBandwidth.isNotEmpty) ...[
                        _SectionTitle('Bandwidth Usage'),
                        const SizedBox(height: 8),
                        _BandwidthChart(
                          dailyBandwidth: _analytics!.dailyBandwidth,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_analytics!.platformStats.isNotEmpty) ...[
                        _SectionTitle('Platform Breakdown'),
                        const SizedBox(height: 8),
                        _PlatformBreakdown(
                          platformStats: _analytics!.platformStats,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_analytics!.totalDownloads > 0) ...[
                        _SectionTitle('Success Rate'),
                        const SizedBox(height: 8),
                        _SuccessRateIndicator(
                          analytics: _analytics!,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 20),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}

/// Time range selector chips.
class _TimeRangeSelector extends StatelessWidget {
  final int selectedDays;
  final ValueChanged<int> onChanged;

  const _TimeRangeSelector({
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _RangeChip(label: '7 Days', days: 7, selectedDays: selectedDays, onTap: onChanged),
          _RangeChip(label: '14 Days', days: 14, selectedDays: selectedDays, onTap: onChanged),
          _RangeChip(label: '30 Days', days: 30, selectedDays: selectedDays, onTap: onChanged),
          _RangeChip(label: '90 Days', days: 90, selectedDays: selectedDays, onTap: onChanged),
          _RangeChip(label: 'All Time', days: 3650, selectedDays: selectedDays, onTap: onChanged),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final int days;
  final int selectedDays;
  final ValueChanged<int> onTap;

  const _RangeChip({
    required this.label,
    required this.days,
    required this.selectedDays,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedDays == days;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(days),
      ),
    );
  }
}

/// Overview stat cards.
class _OverviewCards extends StatelessWidget {
  final DownloadAnalytics analytics;

  const _OverviewCards({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.download,
          title: 'Total Downloads',
          value: '${analytics.totalDownloads}',
          subtitle: '${analytics.completedDownloads} completed',
          color: Colors.blue,
        ),
        _StatCard(
          icon: Icons.check_circle,
          title: 'Success Rate',
          value: '${(analytics.successRate * 100).toStringAsFixed(1)}%',
          subtitle: '${analytics.failedDownloads} failed',
          color: analytics.successRate >= 0.8
              ? Colors.green
              : analytics.successRate >= 0.5
                  ? Colors.orange
                  : Colors.red,
        ),
        _StatCard(
          icon: Icons.data_usage,
          title: 'Total Bandwidth',
          value: analytics.totalBandwidthText,
          subtitle: 'Data downloaded',
          color: Colors.purple,
        ),
        _StatCard(
          icon: Icons.speed,
          title: 'Avg Speed',
          value: analytics.averageSpeedText,
          subtitle: 'Download speed',
          color: Colors.teal,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section title with a divider.
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
      ],
    );
  }
}

/// Line chart showing daily download counts (completed vs failed).
class _DownloadTrendsChart extends StatelessWidget {
  final List<DailyCount> dailyCounts;
  final ColorScheme colorScheme;

  const _DownloadTrendsChart({
    required this.dailyCounts,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyCounts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No download data for this period')),
        ),
      );
    }

    final maxCount = dailyCounts
        .map((d) => d.total)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxCount > 5 ? (maxCount / 5).ceilToDouble() : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _calculateInterval(),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= dailyCounts.length) {
                            return const SizedBox.shrink();
                          }
                          final date = dailyCounts[idx].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: TextStyle(
                                fontSize: 9,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (dailyCounts.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxCount * 1.1,
                  lineBarsData: [
                    // Completed line
                    LineChartBarData(
                      spots: dailyCounts.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.completed.toDouble());
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: Colors.green,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                    // Failed line
                    LineChartBarData(
                      spots: dailyCounts.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.failed.toDouble());
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: Colors.red,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final label = spot.barIndex == 0 ? 'Completed' : 'Failed';
                          return LineTooltipItem(
                            '$label: ${spot.y.toInt()}',
                            TextStyle(
                              color: spot.barIndex == 0 ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ChartLegend(color: Colors.green, label: 'Completed'),
                const SizedBox(width: 16),
                _ChartLegend(color: Colors.red, label: 'Failed'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateInterval() {
    if (dailyCounts.length <= 7) return 1;
    if (dailyCounts.length <= 14) return 2;
    if (dailyCounts.length <= 30) return 5;
    return 10;
  }
}

/// Bar chart showing daily bandwidth usage.
class _BandwidthChart extends StatelessWidget {
  final List<DailyBandwidth> dailyBandwidth;
  final ColorScheme colorScheme;

  const _BandwidthChart({
    required this.dailyBandwidth,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyBandwidth.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No bandwidth data for this period')),
        ),
      );
    }

    final maxBytes = dailyBandwidth
        .map((d) => d.bytes)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatBytes(value.toInt()),
                            style: TextStyle(
                              fontSize: 9,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _calculateInterval(),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= dailyBandwidth.length) {
                            return const SizedBox.shrink();
                          }
                          final date = dailyBandwidth[idx].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: TextStyle(
                                fontSize: 9,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: maxBytes > 0 ? maxBytes * 1.15 : 1,
                  barGroups: dailyBandwidth.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.bytes.toDouble(),
                          color: colorScheme.primary,
                          width: dailyBandwidth.length > 15 ? 4 : 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(3),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final bw = dailyBandwidth[groupIndex];
                        return BarTooltipItem(
                          '${DateFormat('MMM d').format(bw.date)}\n${_formatBytes(bw.bytes)}',
                          TextStyle(
                            color: colorScheme.onInverseSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  double _calculateInterval() {
    if (dailyBandwidth.length <= 7) return 1;
    if (dailyBandwidth.length <= 14) return 2;
    if (dailyBandwidth.length <= 30) return 5;
    return 10;
  }
}

/// Platform breakdown as a horizontal bar list.
class _PlatformBreakdown extends StatelessWidget {
  final List<PlatformStats> platformStats;
  final ColorScheme colorScheme;

  const _PlatformBreakdown({
    required this.platformStats,
    required this.colorScheme,
  });

  static const _platformColors = {
    'YouTube': Colors.red,
    'Instagram': Colors.purple,
    'TikTok': Colors.black,
    'X/Twitter': Colors.blue,
    'Vimeo': Colors.cyan,
    'Facebook': Colors.blueAccent,
    'Dailymotion': Colors.indigo,
    'Reddit': Colors.deepOrange,
  };

  @override
  Widget build(BuildContext context) {
    final maxCount = platformStats
        .map((p) => p.downloadCount)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: platformStats.map((ps) {
            final color = _platformColors[ps.platform] ?? Colors.grey;
            final percentage = maxCount > 0 ? ps.downloadCount / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ps.platform,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${ps.downloadCount} downloads',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        ps.totalBytesText,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Success rate pie chart indicator.
class _SuccessRateIndicator extends StatelessWidget {
  final DownloadAnalytics analytics;
  final ColorScheme colorScheme;

  const _SuccessRateIndicator({
    required this.analytics,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: [
                    PieChartSectionData(
                      value: analytics.completedDownloads.toDouble(),
                      color: Colors.green,
                      radius: 16,
                      title: '',
                    ),
                    PieChartSectionData(
                      value: analytics.failedDownloads.toDouble(),
                      color: Colors.red,
                      radius: 16,
                      title: '',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(
                    color: Colors.green,
                    label: 'Completed',
                    count: analytics.completedDownloads,
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    color: Colors.red,
                    label: 'Failed',
                    count: analytics.failedDownloads,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total: ${analytics.totalDownloads} downloads',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (analytics.firstDownloadDate != null)
                    Text(
                      'Since ${DateFormat('MMM d, yyyy').format(analytics.firstDownloadDate!)}',
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
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $count',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

/// Small legend dot + label for chart legends.
class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
