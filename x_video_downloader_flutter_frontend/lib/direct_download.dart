import 'dart:convert';

import 'package:http/http.dart' as http;

/// Sends a backend `/download` or `/download-index` request in direct mode. When the server answers
/// with the source media URL, the phone fetches the file straight from the
/// source site, so the video bytes skip (and are not billed on) the server.
/// If that fetch fails, it repeats the normal request and the server streams
/// the file as before. The returned response looks like a normal server one.
Future<http.StreamedResponse> sendDownloadRequest(
  http.Client client,
  String endpoint,
  Map<String, String> headers,
  Duration timeout,
) async {
  final directRequest = http.Request('GET', Uri.parse('$endpoint&direct=true'))
    ..headers.addAll(headers);
  final response = await client.send(directRequest).timeout(timeout);
  final contentType = response.headers['content-type'] ?? '';
  if (response.statusCode != 200 ||
      !contentType.contains('application/json')) {
    return response;
  }

  final body = await response.stream.bytesToString();
  Map<String, dynamic>? link;
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic> && decoded['direct_url'] is String) {
      link = decoded;
    }
  } catch (_) {}
  if (link == null) {
    // An API error: hand the already-read body back to the caller.
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      response.statusCode,
      headers: response.headers,
    );
  }

  try {
    final mediaRequest = http.Request('GET', Uri.parse(link['direct_url']))
      ..headers.addAll(Map<String, String>.from(link['headers'] ?? {}));
    final media = await client.send(mediaRequest).timeout(timeout);
    final mediaType = media.headers['content-type'] ?? '';
    if (media.statusCode == 200 &&
        !mediaType.contains('text/') &&
        !mediaType.contains('json') &&
        !mediaType.contains('mpegurl') &&
        !mediaType.contains('dash+xml')) {
      return http.StreamedResponse(
        media.stream,
        200,
        contentLength: media.contentLength,
        headers: {
          ...media.headers,
          'content-type': link['media_type'] as String? ?? 'video/mp4',
          'content-disposition':
              "attachment; filename*=UTF-8''${Uri.encodeComponent(link['filename'] as String? ?? 'video.mp4')}",
        },
      );
    }
    await media.stream.drain<void>();
  } catch (_) {}

  final fallback = http.Request('GET', Uri.parse(endpoint))
    ..headers.addAll(headers);
  return client.send(fallback).timeout(timeout);
}
