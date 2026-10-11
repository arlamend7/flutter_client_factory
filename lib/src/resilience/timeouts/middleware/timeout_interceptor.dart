import '../../../core/cancellation/cancellation_token.dart';
import '../../../http/helpers/request_deadline.dart';
import '../../../http/middleware/contracts/http_middleware.dart';
import '../../../http/middleware/contracts/http_request_handler.dart';
import '../../../http/models/http_request.dart';
import '../../../http/models/http_response.dart';

/// Place before retries for an overall deadline, after them for attempt deadlines.
/// Remains active until the response body is consumed or disposed.
class TimeoutInterceptor implements HttpMiddleware {
  TimeoutInterceptor(this.duration, {this.phase = 'operation'}) {
    if (duration <= Duration.zero) throw ArgumentError.value(duration);
  }
  final Duration duration;
  final String phase;
  @override
  Future<HttpResponse> intercept(HttpRequest request, CancellationToken token,
          HttpRequestHandler next) =>
      RequestDeadline(duration, phase: phase).run(request, token, next);
}
