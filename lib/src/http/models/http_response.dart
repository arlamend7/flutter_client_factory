import 'dart:async';
import 'dart:typed_data';

import '../defaults/http_defaults.dart';
import '../streams/response_body_stream.dart';
import 'http_headers.dart';

/// HTTP status, headers and a single-consumption response body.
/// Always consume the body or await [dispose], including for unsuccessful statuses.
class HttpResponse {
  HttpResponse(
      {required this.statusCode,
      required Stream<List<int>> body,
      HttpHeaders? headers,
      this.uri,
      FutureOr<void> Function()? onClose})
      : headers = headers ?? HttpHeaders(),
        body = ResponseBodyStream(body, onClose: onClose);

  /// Creates a response from an immutable defensive copy of bytes.
  factory HttpResponse.bytes(
      {required int statusCode,
      List<int> bytes = const [],
      HttpHeaders? headers,
      Uri? uri}) {
    return HttpResponse(
        statusCode: statusCode,
        headers: headers,
        uri: uri,
        body: Stream.value(Uint8List.fromList(bytes).asUnmodifiableView()));
  }
  final int statusCode;
  final HttpHeaders headers;
  final Uri? uri;
  final ResponseBodyStream body;
  bool get isSuccessful =>
      statusCode >= HttpDefaults.minimumSuccessStatus &&
      statusCode <= HttpDefaults.maximumSuccessStatus;

  /// Cancels an unread or partially read body and awaits its resource cleanup.
  Future<void> dispose() => body.cancel();

  /// Wraps a body while retaining cleanup of the original response.
  HttpResponse withBody(Stream<List<int>> stream,
          {FutureOr<void> Function()? onClose}) =>
      HttpResponse(
          statusCode: statusCode,
          headers: headers,
          uri: uri,
          body: stream,
          onClose: () async {
            try {
              await dispose();
            } finally {
              await onClose?.call();
            }
          });
}
