import '../../core/cancellation/cancellation_token.dart';
import '../../http/enums/http_method.dart';
import '../../http/middleware/contracts/http_middleware.dart';
import '../../http/middleware/contracts/http_request_handler.dart';
import '../../http/models/http_request.dart';
import '../../http/models/http_response.dart';
import '../services/token_refresh_coordinator.dart';

/// Adds bearer credentials only to allowed origins and retries one eligible 401.
/// Share its coordinator within one authenticated session; writes require opt-in.
class AuthenticationInterceptor implements HttpMiddleware {
  AuthenticationInterceptor(
      {required this.coordinator,
      required Set<String> allowedOrigins,
      this.replayWrites = false})
      : allowedOrigins = Set.unmodifiable(allowedOrigins);
  final TokenRefreshCoordinator coordinator;
  final Set<String> allowedOrigins;
  final bool replayWrites;
  HttpRequest _authorize(HttpRequest request, String? token) => token == null
      ? request
      : request.copyWith(
          headers: request.headers.withValue('authorization', 'Bearer $token'));
  @override
  Future<HttpResponse> intercept(HttpRequest request, CancellationToken token,
      HttpRequestHandler next) async {
    if (!allowedOrigins.contains(request.uri.origin)) {
      return next(request, token);
    }
    final credential = await token.race(coordinator.provider.getToken());
    final response = await next(_authorize(request, credential), token);
    final safe = {HttpMethod.get, HttpMethod.head, HttpMethod.options}
        .contains(request.method);
    if (response.statusCode != 401 ||
        request.body?.isReplayable == false ||
        (!safe && !replayWrites)) {
      return response;
    }
    await response.dispose();
    final refreshed = await coordinator.refresh(credential, token);
    return next(_authorize(request, refreshed), token);
  }
}
