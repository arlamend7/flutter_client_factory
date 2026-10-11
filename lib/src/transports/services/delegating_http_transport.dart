import '../../core/cancellation/cancellation_token.dart';
import '../../http/middleware/contracts/http_request_handler.dart';
import '../../http/models/http_request.dart';
import '../../http/models/http_response.dart';
import '../contracts/http_transport.dart';

/// A non-owning dispatch adapter. Its owner controls resource shutdown.
class DelegatingHttpTransport implements HttpTransport {
  DelegatingHttpTransport(this._send);
  final HttpRequestHandler _send;
  @override
  Future<HttpResponse> send(HttpRequest request, CancellationToken token) =>
      _send(request, token);
  @override
  Future<void> close() async {}
}
