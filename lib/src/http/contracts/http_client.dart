import '../../core/cancellation/cancellation_token.dart';
import '../models/http_request.dart';
import '../models/http_response.dart';

abstract class HttpClient {
  Future<HttpResponse> send(
    HttpRequest request, {
    CancellationToken? cancellationToken,
  });

  /// Prevents new sends from this wrapper; does not close shared transports.
  void dispose();
}
