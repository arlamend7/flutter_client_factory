import '../../../core/cancellation/cancellation_token.dart';
import '../../models/http_request.dart';
import '../../models/http_response.dart';

typedef HttpRequestHandler = Future<HttpResponse> Function(
  HttpRequest request,
  CancellationToken cancellationToken,
);
