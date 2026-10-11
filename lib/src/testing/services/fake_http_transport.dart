import '../../core/cancellation/cancellation_token.dart';
import '../../http/middleware/contracts/http_request_handler.dart';
import '../../http/models/http_request.dart';
import '../../http/models/http_response.dart';
import '../../transports/contracts/http_transport.dart';

/// Executes a handler in memory. Does not simulate real network abortion.
class FakeHttpTransport implements HttpTransport {
  FakeHttpTransport(this._handler);

  final HttpRequestHandler _handler;
  final List<HttpRequest> _requests = [];
  bool _isClosed = false;

  bool get isClosed => _isClosed;
  List<HttpRequest> get requests => List<HttpRequest>.unmodifiable(_requests);

  @override
  Future<HttpResponse> send(
    HttpRequest request,
    CancellationToken cancellationToken,
  ) async {
    if (_isClosed) throw StateError('This transport has been closed.');
    cancellationToken.throwIfCanceled();

    _requests.add(request);
    return _handler(request, cancellationToken);
  }

  @override
  Future<void> close() async {
    _isClosed = true;
  }
}
