import 'dart:typed_data';
import 'http_headers.dart';
import 'http_response.dart';

/// A defensive byte snapshot that can create independently consumable responses.
class BufferedHttpResponse {
  BufferedHttpResponse(
      {required this.statusCode,
      required List<int> bytes,
      required this.headers,
      this.uri})
      : bytes = Uint8List.fromList(bytes).asUnmodifiableView();
  final int statusCode;
  final List<int> bytes;
  final HttpHeaders headers;
  final Uri? uri;
  HttpResponse toResponse() => HttpResponse.bytes(
      statusCode: statusCode, bytes: bytes, headers: headers, uri: uri);
}
