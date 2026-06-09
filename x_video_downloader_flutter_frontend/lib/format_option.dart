/// Represents a single available format/quality for a video.
class FormatOption {
  final String formatId;
  final String ext;
  final String resolution;
  final int? height;
  final int? width;
  final double? fps;
  final String formatType; // "video+audio", "video", "audio"
  final String? vcodec;
  final String? acodec;
  final int? filesize;
  final double? tbr;
  final double? vbr;
  final double? abr;
  final String? formatNote;
  final String ytFormat;

  FormatOption({
    required this.formatId,
    required this.ext,
    required this.resolution,
    this.height,
    this.width,
    this.fps,
    required this.formatType,
    this.vcodec,
    this.acodec,
    this.filesize,
    this.tbr,
    this.vbr,
    this.abr,
    this.formatNote,
    required this.ytFormat,
  });

  factory FormatOption.fromJson(Map<String, dynamic> json) {
    return FormatOption(
      formatId: json['format_id'] as String,
      ext: json['ext'] as String,
      resolution: json['resolution'] as String,
      height: json['height'] as int?,
      width: json['width'] as int?,
      fps: (json['fps'] as num?)?.toDouble(),
      formatType: json['format_type'] as String,
      vcodec: json['vcodec'] as String?,
      acodec: json['acodec'] as String?,
      filesize: json['filesize'] as int?,
      tbr: (json['tbr'] as num?)?.toDouble(),
      vbr: (json['vbr'] as num?)?.toDouble(),
      abr: (json['abr'] as num?)?.toDouble(),
      formatNote: json['format_note'] as String?,
      ytFormat: json['yt_format'] as String,
    );
  }

  bool get isAudioOnly => formatType == 'audio';
  bool get hasVideo => formatType != 'audio';

  String get filesizeText {
    if (filesize == null || filesize! <= 0) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = filesize!.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  String get qualityLabel {
    if (isAudioOnly) {
      final abrKbps = abr != null ? (abr! * 1024).round() : null;
      return abrKbps != null ? '$abrKbps kbps' : 'Audio';
    }
    return resolution;
  }

  String get shortDescription {
    final parts = <String>[];
    parts.add(qualityLabel);
    if (ext.isNotEmpty) parts.add(ext.toUpperCase());
    if (filesizeText.isNotEmpty) parts.add(filesizeText);
    if (formatNote != null && formatNote!.isNotEmpty) parts.add(formatNote!);
    return parts.join(' · ');
  }
}

/// Result from the /formats endpoint.
class FormatsResult {
  final String title;
  final String? thumbnail;
  final int? duration;
  final List<FormatOption> formats;

  FormatsResult({
    required this.title,
    this.thumbnail,
    this.duration,
    required this.formats,
  });

  factory FormatsResult.fromJson(Map<String, dynamic> json) {
    return FormatsResult(
      title: json['title'] as String? ?? 'Video',
      thumbnail: json['thumbnail'] as String?,
      duration: json['duration'] as int?,
      formats: (json['formats'] as List)
          .map((f) => FormatOption.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Best combined format (video+audio), or best video format.
  FormatOption? get bestFormat {
    final combined = formats.where((f) => f.formatType == 'video+audio').toList();
    if (combined.isNotEmpty) return combined.first;
    final video = formats.where((f) => f.hasVideo).toList();
    if (video.isNotEmpty) return video.first;
    return formats.isNotEmpty ? formats.first : null;
  }
}
