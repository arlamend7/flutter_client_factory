import '../../../core/cancellation/cancellation_token.dart';
import '../../models/http_request.dart';
import '../../models/http_response.dart';
import 'http_request_handler.dart';

/// Middleware may return a response without forwarding to [next].
typedef HttpInterceptor = Future<HttpResponse> Function(
  HttpRequest request,
  CancellationToken cancellationToken,
  HttpRequestHandler next,
);
