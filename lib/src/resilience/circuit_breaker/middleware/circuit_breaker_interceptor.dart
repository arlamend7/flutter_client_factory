import '../../../core/cancellation/cancellation_token.dart';
import '../../../core/errors/network_exception.dart';
import '../../../core/errors/request_timeout_exception.dart';
import '../../../http/middleware/contracts/http_middleware.dart';
import '../../../http/middleware/contracts/http_request_handler.dart';
import '../../../http/models/http_request.dart';
import '../../../http/models/http_response.dart';
import '../errors/circuit_open_exception.dart';

/// Scope an instance to a single backend. One probe is allowed after cooldown.
class CircuitBreakerInterceptor implements HttpMiddleware {
  CircuitBreakerInterceptor(
      {this.failureThreshold = 5,
      this.breakDuration = const Duration(seconds: 30),
      DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    if (failureThreshold < 1 || breakDuration <= Duration.zero) {
      throw ArgumentError('Invalid circuit options.');
    }
  }
  final int failureThreshold;
  final Duration breakDuration;
  final DateTime Function() _clock;
  int _failures = 0;
  int _generation = 0;
  DateTime? _openUntil;
  bool _probing = false;
  void _failure() {
    _failures++;
    if (_failures < failureThreshold) return;
    _openUntil = _clock().add(breakDuration);
    _generation++;
  }

  @override
  Future<HttpResponse> intercept(HttpRequest request, CancellationToken token,
      HttpRequestHandler next) async {
    token.throwIfCanceled();
    final until = _openUntil;
    final probe = until != null;
    if (until != null && (_clock().isBefore(until) || _probing)) {
      throw CircuitOpenException(until);
    }
    if (probe) _probing = true;
    final generation = _generation;
    try {
      final response = await next(request, token);
      if (generation != _generation) return response;
      if (response.statusCode >= 500 || response.statusCode == 429) {
        _failure();
      } else {
        _failures = 0;
        _openUntil = null;
      }
      return response;
    } catch (error) {
      if (!token.isCanceled &&
          generation == _generation &&
          (error is NetworkException || error is RequestTimeoutException)) {
        _failure();
      }
      rethrow;
    } finally {
      if (probe) _probing = false;
    }
  }
}
