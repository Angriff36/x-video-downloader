import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import 'download_record.dart';
import 'download_queue_manager.dart';
import 'queue_item.dart';

/// Regex to detect supported video platform URLs (duplicated from main.dart to avoid coupling).
final _batchUrlPattern = RegExp(
  r'(https?://(?:'
  r'(?:www\.)?(?:x\.com|twitter\.com)/\w+/status/\d+'
  r'|(?:www\.)?(?:youtube\.com/(?:watch\?v=|shorts/|embed/)|youtu\.be/)'
  r'|(?:www\.)?(?:instagram\.com/(?:reel|p|tv)/)'
  r'|(?:www\.)?(?:tiktok\.com/@[^/]+/video/)'
  r'|(?:www\.)?(?:facebook\.com/(?:watch|reel|videos/))'
  r'|(?:www\.)?(?:vimeo\.com/\d+)'
  r'|(?:www\.)?(?:reddit\.com/r/[^/]+/comments/)'
  r'|(?:www\.)?(?:dailymotion\.com/video/)'
  r')[^\s<>"{}|\\^`\[\]]*)',
  caseSensitive: false,
);

/// Result of validating a batch of URLs.
class _BatchValidationResult {
  final List<_ValidatedUrl> valid;
  final List<_InvalidUrl> invalid;

  _BatchValidationResult({required this.valid, required this.invalid});
}

class _ValidatedUrl {
  final String url;
  final String platform;

  _ValidatedUrl({required this.url, required this.platform});
}

class _InvalidUrl {
  final String input;
  final String reason;

  _InvalidUrl({required this.input, required this.reason});
}

/// Validates a list of raw text lines into valid/invalid URLs.
_BatchValidationResult _validateUrls(List<String> rawLines) {
  final valid = <_ValidatedUrl>[];
  final invalid = <_InvalidUrl>[];
  final seen = <String>{};

  for (final line in rawLines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    // Try to match as a video URL
    final match = _batchUrlPattern.firstMatch(trimmed);
    if (match != null) {
      final url = match.group(0)!;
      if (seen.contains(url)) continue; // dedupe
      seen.add(url);
      valid.add(_ValidatedUrl(
        url: url,
        platform: DownloadRecord.detectPlatform(url),
      ));
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      // It's a URL but not a supported platform
      if (!seen.contains(trimmed)) {
        seen.add(trimmed);
        invalid.add(_InvalidUrl(
          input: trimmed,
          reason: 'Unsupported platform',
        ));
      }
    } else {
      invalid.add(_InvalidUrl(
        input: trimmed.length > 80 ? '${trimmed.substring(0, 80)}...' : trimmed,
        reason: 'Not a valid URL',
      ));
    }
  }

  return _BatchValidationResult(valid: valid, invalid: invalid);
}

/// Screen for batch importing multiple video URLs at once.
///
/// Supports three input methods:
/// 1. Bulk paste from clipboard
/// 2. Text file upload (.txt, .csv)
/// 3. Manual multi-line text input
/// 4. Initial text from share intent (multiple URLs shared from another app)
class BatchImportScreen extends StatefulWidget {
  final DownloadQueueManager queueManager;
  final String? initialText;

  const BatchImportScreen({
    super.key,
    required this.queueManager,
    this.initialText,
  });

  @override
  State<BatchImportScreen> createState() => _BatchImportScreenState();
}

class _BatchImportScreenState extends State<BatchImportScreen> {
  final TextEditingController _textController = TextEditingController();
  List<_ValidatedUrl> _validUrls = [];
  List<_InvalidUrl> _invalidUrls = [];
  bool _isValidated = false;
  bool _isImporting = false;
  bool _isReadingFile = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _textController.text = widget.initialText!;
      // Auto-validate after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validate();
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Parse the text input and validate URLs.
  void _validate() {
    final lines = _textController.text.split(RegExp(r'\n'));
    final result = _validateUrls(lines);
    setState(() {
      _validUrls = result.valid;
      _invalidUrls = result.invalid;
      _isValidated = true;
    });
  }

  /// Load URLs from the system clipboard.
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        if (_textController.text.isNotEmpty) {
          _textController.text = '${_textController.text}\n${data.text}';
        } else {
          _textController.text = data.text!;
        }
        _isValidated = false;
      });
      _validate();
    }
  }

  /// Load URLs from a text file.
  Future<void> _loadFromFile() async {
    setState(() => _isReadingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv', 'text'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isReadingFile = false);
        return;
      }

      final file = result.files.first;
      String content;

      if (file.path != null) {
        // Read from file path (mobile/desktop)
        content = await File(file.path!).readAsString();
      } else if (file.bytes != null) {
        // Read from bytes (web)
        content = String.fromCharCodes(file.bytes!);
      } else {
        setState(() => _isReadingFile = false);
        return;
      }

      setState(() {
        if (_textController.text.isNotEmpty) {
          _textController.text = '${_textController.text}\n$content';
        } else {
          _textController.text = content;
        }
        _isValidated = false;
        _isReadingFile = false;
      });
      _validate();
    } catch (e) {
      setState(() => _isReadingFile = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read file: $e')),
        );
      }
    }
  }

  /// Remove a URL from the valid list.
  void _removeValidUrl(int index) {
    setState(() {
      _validUrls.removeAt(index);
    });
  }

  /// Add all valid URLs to the download queue.
  Future<void> _importToQueue() async {
    if (_validUrls.isEmpty) return;

    setState(() => _isImporting = true);

    final items = _validUrls.map((v) => QueueItem(
      url: v.url,
      platform: v.platform,
      title: 'Pending: ${v.platform}',
      createdAt: DateTime.now(),
    )).toList();

    await widget.queueManager.addBatchToQueue(items);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${items.length} URLs to download queue'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, items.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Import'),
        actions: [
          IconButton(
            icon: const Icon(Icons.paste),
            tooltip: 'Paste from clipboard',
            onPressed: _pasteFromClipboard,
          ),
          IconButton(
            icon: _isReadingFile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            tooltip: 'Load from file',
            onPressed: _isReadingFile ? null : _loadFromFile,
          ),
        ],
      ),
      body: Column(
        children: [
          // Input area
          _buildInputArea(),
          const Divider(height: 1),

          // Validation results
          Expanded(child: _buildResults()),
        ],
      ),
      // Import button
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paste URLs or load from file',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Paste one URL per line...\n'
                  'Supports: X/Twitter, YouTube, Instagram, TikTok, Facebook, Vimeo, Reddit, Dailymotion',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Clear',
                onPressed: () {
                  _textController.clear();
                  setState(() {
                    _validUrls = [];
                    _invalidUrls = [];
                    _isValidated = false;
                  });
                },
              ),
            ),
            onChanged: (_) {
              if (_isValidated) {
                setState(() => _isValidated = false);
              }
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _validate,
              icon: const Icon(Icons.checklist, size: 18),
              label: const Text('Validate URLs'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (!_isValidated) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Enter URLs above and tap Validate',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final total = _validUrls.length + _invalidUrls.length;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Summary header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 18),
              const SizedBox(width: 6),
              Text(
                '${_validUrls.length} valid',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(width: 16),
              if (_invalidUrls.isNotEmpty) ...[
                Icon(Icons.error, color: Colors.red[700], size: 18),
                const SizedBox(width: 6),
                Text(
                  '${_invalidUrls.length} invalid',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '$total total',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Valid URLs
        if (_validUrls.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'VALID URLs',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...List.generate(_validUrls.length, (i) {
            final v = _validUrls[i];
            return _buildUrlTile(
              index: i,
              url: v.url,
              platform: v.platform,
              isValid: true,
              onRemove: () => _removeValidUrl(i),
            );
          }),
        ],

        // Invalid URLs
        if (_invalidUrls.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'INVALID URLs',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.red[400],
                letterSpacing: 0.5,
              ),
            ),
          ),
          ..._invalidUrls.map((inv) => _buildInvalidTile(inv)),
        ],
      ],
    );
  }

  Widget _buildUrlTile({
    required int index,
    required String url,
    required String platform,
    required bool isValid,
    required VoidCallback onRemove,
  }) {
    final platformIcon = _platformIcon(platform);
    return Dismissible(
      key: ValueKey('valid_${index}_$url'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red[100],
        child: Icon(Icons.delete, color: Colors.red[700]),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: Icon(platformIcon, size: 16, color: Colors.green[700]),
        ),
        title: Text(
          url,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: Text(
          platform,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: onRemove,
          tooltip: 'Remove',
        ),
      ),
    );
  }

  Widget _buildInvalidTile(_InvalidUrl inv) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        child: Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
      ),
      title: Text(
        inv.input,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: Colors.red[700]),
      ),
      subtitle: Text(
        inv.reason,
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildBottomBar() {
    final canImport = _isValidated && _validUrls.isNotEmpty && !_isImporting;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canImport ? _importToQueue : null,
            icon: _isImporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download),
            label: Text(
              _isImporting
                  ? 'Importing...'
                  : _isValidated
                      ? 'Add ${_validUrls.length} URL${_validUrls.length != 1 ? 's' : ''} to Queue'
                      : 'Add to Queue',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'x/twitter':
        return Icons.close;
      case 'youtube':
        return Icons.play_circle_filled;
      case 'instagram':
        return Icons.camera_alt;
      case 'tiktok':
        return Icons.music_note;
      case 'facebook':
        return Icons.thumb_up;
      case 'vimeo':
        return Icons.videocam;
      case 'reddit':
        return Icons.forum;
      case 'dailymotion':
        return Icons.movie;
      default:
        return Icons.link;
    }
  }
}
