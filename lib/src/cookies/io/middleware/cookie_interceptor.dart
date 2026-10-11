import '../../../core/cancellation/cancellation_token.dart';
import '../../../http/middleware/contracts/http_middleware.dart';
import '../../../http/middleware/contracts/http_request_handler.dart';
import '../../../http/models/http_request.dart';
import '../../../http/models/http_response.dart';
import '../services/cookie_jar.dart';

/// Use a transport with automatic redirects disabled when collecting redirect cookies.
class CookieInterceptor implements HttpMiddleware {
  CookieInterceptor(this.jar);
  final CookieJar jar;
  @override
  Future<HttpResponse> intercept(HttpRequest request, CancellationToken token,
      HttpRequestHandler next) async {
    final value = jar.header(request.uri);
    final outgoing = value.isEmpty || request.headers.contains('cookie')
        ? request
        : request.copyWith(headers: request.headers.withValue('cookie', value));
    final response = await next(outgoing, token);
    jar.store(response.uri ?? request.uri, response.headers['set-cookie']);
    return response;
  }
}
