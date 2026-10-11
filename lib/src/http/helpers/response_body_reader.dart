import 'dart:convert';
import 'dart:typed_data';
import '../models/buffered_http_response.dart';
import '../models/http_response.dart';

/// Consumes and disposes a response with a configurable buffering limit.
/// Text decoding is UTF-8; JSON decoding requires an explicit domain converter.
class ResponseBodyReader {
  /// Maximum bytes buffered per call; use the raw body stream for larger data.
  const ResponseBodyReader({this.maxBytes = 8 * 1024 * 1024});
  final int maxBytes;

  /// Returns an immutable compact byte buffer; throws when [maxBytes] is exceeded.
  Future<List<int>> readBytes(HttpResponse response) async {
    final bytes = BytesBuilder();
    try {
      if (maxBytes < 0) throw ArgumentError.value(maxBytes, 'maxBytes');
      await for (final chunk in response.body) {
        if (bytes.length + chunk.length > maxBytes) {
          throw StateError(
              'Response exceeds the $maxBytes byte buffering limit.');
        }
        bytes.add(chunk);
      }
      return bytes.takeBytes().asUnmodifiableView();
    } finally {
      await response.dispose();
    }
  }

  /// Keeps response metadata alongside a reusable body snapshot.
  Future<BufferedHttpResponse> buffer(HttpResponse response) async =>
      BufferedHttpResponse(
          statusCode: response.statusCode,
          headers: response.headers,
          uri: response.uri,
          bytes: await readBytes(response));

  /// Decodes UTF-8 strictly and releases the response even on malformed input.
  Future<String> readText(HttpResponse response) async =>
      utf8.decode(await readBytes(response));

  /// Parses JSON, then invokes [decode] to validate and construct the domain value.
  Future<T> readJson<T>(
      HttpResponse response, T Function(Object? json) decode) async {
    final Object? json = jsonDecode(await readText(response));
    return decode(json);
  }
}
