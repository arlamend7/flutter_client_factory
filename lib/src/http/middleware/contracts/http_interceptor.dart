import '../../../core/cancellation/cancellation_token.dart';
import '../../models/http_request.dart';
import '../../models/http_response.dart';
import 'http_request_handler.dart';

/// Middleware may return a response without forwarding to [next].
/// Calling [next] again repeats only the interceptors later in the list.
/// Consume or dispose a discarded response before resending, and only resend
/// requests whose method and body are safe to replay.
typedef HttpInterceptor = Future<HttpResponse> Function(
  HttpRequest request,
  CancellationToken cancellationToken,
  HttpRequestHandler next,
);
