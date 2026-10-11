import '../../../core/cancellation/cancellation_token.dart';
import '../../models/http_request.dart';
import '../../models/http_response.dart';
import 'http_request_handler.dart';

abstract class HttpMiddleware {
  Future<HttpResponse> intercept(HttpRequest request,
      CancellationToken cancellationToken, HttpRequestHandler next);
}
