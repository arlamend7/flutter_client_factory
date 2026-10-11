import 'dart:async';
import '../../core/cancellation/cancellation_token.dart';
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

  void fail(Object error, [StackTrace? stackTrace]) {
    if (completed) throw StateError('Request already completed.');
    _remove();
    _result.completeError(error, stackTrace);
  }
}
