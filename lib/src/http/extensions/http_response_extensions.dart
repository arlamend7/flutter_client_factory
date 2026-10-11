import 'dart:async';
import '../errors/http_status_exception.dart';
import '../helpers/response_body_reader.dart';
import '../models/buffered_http_response.dart';
import '../models/http_response.dart';

/// Bounded body reading and explicit response ownership conveniences.
extension HttpResponseExtensions on HttpResponse {
  /// Consumes and releases this response, including on failure.
  Future<List<int>> readBytes({int maxBytes = 8 * 1024 * 1024}) =>
      ResponseBodyReader(maxBytes: maxBytes).readBytes(this);

  /// Consumes UTF-8 text and releases this response.
  Future<String> readText({int maxBytes = 8 * 1024 * 1024}) =>
      ResponseBodyReader(maxBytes: maxBytes).readText(this);

  /// Parses JSON and passes it to an explicit domain decoder.
  /// Does not implicitly reject non-successful HTTP statuses.
  Future<T> readJson<T>(
          {required T Function(Object? json) decode,
          int maxBytes = 8 * 1024 * 1024}) =>
      ResponseBodyReader(maxBytes: maxBytes).readJson(this, decode);

  /// Consumes the stream into a reusable bounded snapshot.
  Future<BufferedHttpResponse> buffer({int maxBytes = 8 * 1024 * 1024}) =>
      ResponseBodyReader(maxBytes: maxBytes).buffer(this);

  /// Returns this response for 2xx; otherwise releases it and throws metadata.
  Future<HttpResponse> requireSuccess() async {
    if (isSuccessful) return this;
    final error = HttpStatusException(statusCode, headers: headers, uri: uri);
    await dispose();
    throw error;
  }

  /// Releases the response when processing finishes, even if processing fails.
  /// Returned values must not depend on the response remaining open.
  Future<T> use<T>(FutureOr<T> Function(HttpResponse response) process) async {
    try {
      return await process(this);
    } finally {
      await dispose();
    }
  }
}
