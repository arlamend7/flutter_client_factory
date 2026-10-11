import 'dart:math';
import '../../../core/cancellation/cancellation_token.dart';
import '../../../core/errors/network_exception.dart';
import '../../../core/errors/request_timeout_exception.dart';
import '../../../http/enums/http_method.dart';
import '../../../http/helpers/http_date_codec.dart';
import '../../../http/middleware/contracts/http_middleware.dart';
import '../../../http/middleware/contracts/http_request_handler.dart';
import '../../../http/models/http_request.dart';
import '../../../http/models/http_response.dart';
import '../configuration/retry_options.dart';

/// Retries replayable, eligible operations before their response is delivered.
/// Honors Retry-After; it never retries partially consumed response bodies.
class RetryInterceptor implements HttpMiddleware {
  RetryInterceptor(
      {RetryOptions? options,
      double Function()? random,
      DateTime Function()? clock,
      Future<void> Function(Duration, CancellationToken)? delay})
      : options = options ?? RetryOptions(),
        _random = random ?? Random().nextDouble,
        _clock = clock ?? DateTime.now,
        _delay = delay ?? ((duration, token) => token.wait(duration));
  final RetryOptions options;
  final double Function() _random;
  final DateTime Function() _clock;
  final Future<void> Function(Duration, CancellationToken) _delay;
  @override
  Future<HttpResponse> intercept(HttpRequest request, CancellationToken token,
      HttpRequestHandler next) async {
    final safe = {HttpMethod.get, HttpMethod.head, HttpMethod.options}
        .contains(request.method);
    if ((!safe && !options.retryWrites) ||
        request.body?.isReplayable == false) {
      return next(request, token);
    }
    for (var attempt = 1;; attempt++) {
      token.throwIfCanceled();
      HttpResponse? response;
      try {
        response = await next(request.copyWith(), token);
      } catch (error) {
        if (token.isCanceled ||
            attempt >= options.maxAttempts ||
            (error is! NetworkException && error is! RequestTimeoutException)) {
          rethrow;
        }
      }
      if (response != null &&
          (!options.statuses.contains(response.statusCode) ||
              attempt >= options.maxAttempts)) {
        return response;
      }
      var duration = Duration(
          microseconds: (min(
                      options.maxDelay.inMicroseconds,
                      options.baseDelay.inMicroseconds *
                          pow(2, min(attempt - 1, 30))) *
                  _random().clamp(0, 1))
              .round());
      if (response != null) {
        final values = response.headers['retry-after'];
        if (values.isNotEmpty) {
          final seconds = int.tryParse(values.first);
          final date = const HttpDateCodec().parse(values.first);
          final requested = seconds != null
              ? Duration(seconds: max(0, seconds))
              : date?.difference(_clock().toUtc());
          // Do not violate a server delay by retrying before its requested time.
          if (requested != null && requested > options.maxDelay) {
            return response;
          }
          if (requested != null && requested > duration) duration = requested;
        }
        await response.dispose();
      }
      await _delay(duration, token);
    }
  }
}
