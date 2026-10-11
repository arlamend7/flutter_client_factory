import '../../core/cancellation/cancellation_token.dart';
import '../../http/models/http_request.dart';
import '../../http/models/http_response.dart';

/// Owns network I/O, connections, and cancellation of request/body streams.
abstract class HttpTransport {
  Future<HttpResponse> send(
    HttpRequest request,
    CancellationToken cancellationToken,
  );

  /// Stops accepting requests and releases transport resources.
  Future<void> close();
}
