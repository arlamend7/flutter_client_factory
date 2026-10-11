import '../models/http_headers.dart';

/// An explicitly rejected HTTP status, without buffering an error body.
class HttpStatusException implements Exception {
  const HttpStatusException(this.statusCode, {required this.headers, this.uri});
  final int statusCode;
  final HttpHeaders headers;
  final Uri? uri;
  @override
  String toString() => 'HttpStatusException: HTTP $statusCode';
}
