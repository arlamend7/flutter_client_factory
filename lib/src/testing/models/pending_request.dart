import 'dart:async';
import 'dart:convert';
import '../../core/cancellation/cancellation_token.dart';
import '../../http/models/http_headers.dart';
import '../../http/models/http_request.dart';
import '../../http/models/http_response.dart';

/// A captured request that tests must match and complete or cancel.
class PendingRequest {
  PendingRequest(this.request, this.token) {
    _remove = token.onCancel(() {
      if (_result.isCompleted) return;
      _result.completeError(token.error);
    });
  }
  final HttpRequest request;
  final CancellationToken token;
  final Completer<HttpResponse> _result = Completer<HttpResponse>();
  void Function() _remove = () {};
  bool matched = false;
  bool get completed => _result.isCompleted;
  Future<HttpResponse> get response => _result.future;
  void flush(HttpResponse response) {
    if (completed) throw StateError('Request already completed.');
    _remove();
    _result.complete(response);
  }

  /// Completes with UTF-8 JSON, defaulting to HTTP 200 and JSON content type.
  void flushJson(Object? value,
          {int statusCode = 200, Map<String, String> headers = const {}}) =>
      flush(HttpResponse.bytes(
          statusCode: statusCode,
          bytes: utf8.encode(jsonEncode(value)),
          uri: request.uri,
          headers: HttpHeaders.single(
                  {'content-type': 'application/json; charset=utf-8'})
              .merge(HttpHeaders.single(headers))));

  /// Completes with UTF-8 text; custom headers override default content type.
  void flushText(String text,
          {int statusCode = 200, Map<String, String> headers = const {}}) =>
      flush(HttpResponse.bytes(
          statusCode: statusCode,
          bytes: utf8.encode(text),
          uri: request.uri,
          headers:
              HttpHeaders.single({'content-type': 'text/plain; charset=utf-8'})
                  .merge(HttpHeaders.single(headers))));

  void fail(Object error, [StackTrace? stackTrace]) {
    if (completed) throw StateError('Request already completed.');
    _remove();
    _result.completeError(error, stackTrace);
  }
}
