import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'download_record.dart';

/// Service for sharing downloaded videos and metadata to other apps.
class ShareService {
  /// Share a video file along with its metadata text.
  ///
  /// On iOS and Android, uses XFile-based sharing which allows the file
  /// to be picked up by social media, messaging, and cloud storage apps.
  /// Falls back to text-only sharing if the file doesn't exist.
  static Future<void> shareVideo(
    BuildContext context,
    DownloadRecord record,
  ) async {
    if (record.filePath.isEmpty || record.status != 'completed') {
      await _shareTextOnly(record);
      return;
    }

    final file = File(record.filePath);
    if (!await file.exists()) {
      await _shareTextOnly(record);
      return;
    }
    if (!context.mounted) return;

    final text = _buildShareText(record);
    final xFile = XFile(record.filePath, mimeType: 'video/mp4');

    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    await Share.shareXFiles([xFile], text: text, sharePositionOrigin: origin);
  }

  /// Share only the video metadata (title + URL) as text.
  static Future<void> _shareTextOnly(DownloadRecord record) async {
    final text = _buildShareText(record);
    await Share.share(text);
  }

  /// Build a share text string with video metadata.
  static String _buildShareText(DownloadRecord record) {
    final parts = <String>[record.title];
    if (record.url.isNotEmpty) {
      parts.add(record.url);
    }
    return parts.join('\n');
  }
}
