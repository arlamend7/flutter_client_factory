import 'dart:async';
import '../../../core/cancellation/cancellation_token.dart';
import '../../../http/enums/http_method.dart';
import '../../../http/middleware/contracts/http_middleware.dart';
import '../../../http/middleware/contracts/http_request_handler.dart';
import '../../../http/models/http_request.dart';
import '../../../http/models/http_response.dart';

/// Opt-in duplicate reads. The first response wins; losing work is canceled.
/// Place authentication before this policy. It only repeats the original URI.
class HedgingInterceptor implements HttpMiddleware {
  HedgingInterceptor(
      {this.delay = const Duration(milliseconds: 300), this.maxAttempts = 2}) {
    if (delay < Duration.zero || maxAttempts < 1 || maxAttempts > 8) {
      throw ArgumentError('Invalid hedging budget.');
    }
  }
  final Duration delay;
  final int maxAttempts;
  @override
  Future<HttpResponse> intercept(HttpRequest request, CancellationToken parent,
      HttpRequestHandler next) async {
    if (!{HttpMethod.get, HttpMethod.head}.contains(request.method) ||
        request.body != null ||
        maxAttempts == 1) {
      return next(request, parent);
    }
    final result = Completer<HttpResponse>();
    final tokens =
        List.generate(maxAttempts, (_) => CancellationToken.linked([parent]));
    var failures = 0;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final token = tokens[attempt];
      unawaited(Future<void>(() async {
        try {
          if (attempt > 0) await token.wait(delay * attempt);
          token.throwIfCanceled();
          final response = await next(request.copyWith(), token);
          if (parent.isCanceled) {
            await response.dispose();
            parent.throwIfCanceled();
          }
          if (result.isCompleted) {
            await response.dispose();
            token.dispose();
            return;
          }
          for (final other in tokens) {
            if (!identical(other, token)) other.cancel('Hedge lost.');
          }
          result.complete(
              response.withBody(response.body, onClose: token.dispose));
        } catch (error, stack) {
          failures++;
          token.dispose();
          if (!result.isCompleted && failures == maxAttempts) {
            result.completeError(error, stack);
          }
        }
      }));
    }
    return parent.race(result.future);
  }
}
