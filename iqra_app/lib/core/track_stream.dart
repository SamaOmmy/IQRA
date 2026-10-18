import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Whole-surah recordings are long MP3 files without an index. Asking the player to jump to a time inside one makes it read the
/// file from the start up to that time (minutes, for a verse deep in a long surah). These files are constant-bitrate, so a time
/// maps to a byte position; this tiny server on the device itself serves the recording starting from such a position, which the
/// player then simply plays. Nothing leaves the device except the normal download of the audio.
class TrackStream {
  static HttpServer? _server;
  static final Map<String, int> _sizes = {};

  static Future<void> _ensure() async {
    if (_server != null) return;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen(_serve, onError: (_) {});
  }

  /// The size of the file in bytes (0 when it cannot be found out).
  static Future<int> sizeOf(String url) async {
    final known = _sizes[url];
    if (known != null) return known;
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url))..headers['Range'] = 'bytes=0-0';
      final res = await client.send(req).timeout(const Duration(seconds: 6));
      final range = res.headers['content-range'];
      var size = 0;
      if (range != null && range.contains('/')) {
        size = int.tryParse(range.split('/').last) ?? 0;
      } else if (res.statusCode == 200) {
        size = res.contentLength ?? 0;
      }
      unawaited(res.stream.drain<void>().catchError((_) {}));
      if (size > 0) _sizes[url] = size;
      return size;
    } catch (_) {
      return 0;
    } finally {
      client.close();
    }
  }

  /// The address on this device that serves [url] from byte [from] onwards.
  static Future<String> urlFor(String url, int from) async {
    await _ensure();
    return 'http://127.0.0.1:${_server!.port}/t?from=$from&u=${Uri.encodeQueryComponent(url)}';
  }

  static Future<void> _serve(HttpRequest request) async {
    final client = http.Client();
    try {
      final from = int.tryParse(request.uri.queryParameters['from'] ?? '') ?? 0;
      final upstream = request.uri.queryParameters['u'];
      if (upstream == null) {
        request.response.statusCode = 400;
        await request.response.close();
        return;
      }
      final req = http.Request('GET', Uri.parse(upstream));
      if (from > 0) req.headers['Range'] = 'bytes=$from-';
      final res = await client.send(req).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200 && res.statusCode != 206) {
        request.response.statusCode = 502;
        await request.response.close();
        return;
      }
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType('audio', 'mpeg');
      request.response.bufferOutput = false;
      await request.response.addStream(res.stream);
      await request.response.close();
    } catch (e) {
      // the player stopped listening (a new verse was chosen), or the connection dropped
      if (kDebugMode) debugPrint('track stream ended: $e');
      try {
        await request.response.close();
      } catch (_) {}
    } finally {
      client.close();
    }
  }
}
