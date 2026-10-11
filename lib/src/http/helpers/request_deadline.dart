import 'dart:async';
import '../../core/cancellation/cancellation_token.dart';
import '../../core/errors/request_timeout_exception.dart';
import '../middleware/contracts/http_request_handler.dart';
import '../models/http_request.dart';
import '../models/http_response.dart';

/// Place outside retries for an overall deadline, inside for attempt deadlines.
/// The deadline remains active until the response body is consumed or disposed.
class RequestDeadline {
  RequestDeadline(this.duration, {this.phase = 'operation'}) {
    if (duration <= Duration.zero) throw ArgumentError.value(duration);
  }
  final Duration duration;
  final String phase;
  Future<HttpResponse> run(HttpRequest request, CancellationToken parent,
      HttpRequestHandler next) async {
    parent.throwIfCanceled();
    final token = CancellationToken.linked([parent]);
    final timer = Timer(
        duration,
        () =>
            token.cancelWith(RequestTimeoutException(duration, phase: phase)));
    final pending = Future<HttpResponse>.sync(() => next(request, token));
    unawaited(pending.then<void>((response) async {
      if (token.isCanceled) await response.dispose();
    }, onError: (Object e, StackTrace s) {}));
    try {
      final response = await token.race(pending);
      final remove = token.onCancel(() {
        unawaited(response.body.abort(token.error));
      });
      return response.withBody(response.body, onClose: () {
        remove();
        timer.cancel();
        token.dispose();
      });
    } catch (_) {
      timer.cancel();
      token.dispose();
      rethrow;
    }
  }
}
