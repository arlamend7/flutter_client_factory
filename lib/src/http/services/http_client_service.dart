import '../../core/cancellation/cancellation_token.dart';
import '../../transports/contracts/http_transport.dart';
import '../bodies/observed_request_body.dart';
import '../configuration/http_client_options.dart';
import '../contracts/http_client.dart';
import '../events/models/download_progress_event.dart';
import '../events/models/request_sent_event.dart';
import '../events/models/response_completed_event.dart';
import '../events/models/response_headers_event.dart';
import '../events/models/upload_progress_event.dart';
import '../helpers/request_deadline.dart';
import '../helpers/request_uri_resolver.dart';
import '../middleware/contracts/http_request_handler.dart';
import '../models/http_request.dart';
import '../models/http_response.dart';

/// Applies client options and middleware to a borrowed transport.
///
/// The transport owner, either a factory or caller, is responsible for closing it.
class HttpClientService implements HttpClient {
  HttpClientService({
    required HttpTransport transport,
    HttpClientOptions? options,
    bool Function()? isTransportAvailable,
  })  : _transport = transport,
        _options = options ?? HttpClientOptions(),
        _isTransportAvailable = isTransportAvailable;

  final HttpTransport _transport;
  final HttpClientOptions _options;
  final bool Function()? _isTransportAvailable;
  final RequestUriResolver _uriResolver = const RequestUriResolver();
  bool _isDisposed = false;

  @override
  Future<HttpResponse> send(
    HttpRequest request, {
    CancellationToken? cancellationToken,
  }) async {
    _ensureAvailable();
    final token = cancellationToken ?? CancellationToken();
    token.throwIfCanceled();

    final prepared = _prepare(request);
    HttpRequestHandler handler = _sendTransport;

    for (final interceptor in _options.interceptors.reversed) {
      final next = handler;
      handler =
          (current, cancellation) => interceptor(current, cancellation, next);
    }

    final timeout = prepared.timeout ?? _options.timeout;
    if (timeout == null) return handler(prepared, token);
    return RequestDeadline(timeout).run(prepared, token, handler);
  }

  HttpRequest _prepare(HttpRequest request) {
    final uri = _uriResolver.resolve(request.uri, _options.baseUri);
    var headers = _options.headers.merge(request.headers);
    final contentType = request.body?.contentType;

    if (contentType != null && !headers.contains('content-type')) {
      headers = headers.withValue('content-type', contentType);
    }

    return request.copyWith(uri: uri, headers: headers);
  }

  Future<HttpResponse> _sendTransport(
      HttpRequest request, CancellationToken token) async {
    _ensureAvailable();
    token.throwIfCanceled();
    final observer = _options.onEvent;
    if (observer == null) return _transport.send(request, token);
    observer(RequestSentEvent(request.uri));
    final body = request.body;
    final outgoing = body == null
        ? request
        : request.copyWith(
            body: ObservedRequestBody(body,
                (count) => observer(UploadProgressEvent(request.uri, count))));
    final response = await _transport.send(outgoing, token);
    try {
      observer(ResponseHeadersEvent(request.uri, response.statusCode));
    } catch (_) {
      await response.dispose();
      rethrow;
    }
    Stream<List<int>> observed() async* {
      var count = 0;
      await for (final chunk in response.body) {
        count += chunk.length;
        observer(DownloadProgressEvent(request.uri, count));
        yield chunk;
      }
      observer(ResponseCompletedEvent(request.uri));
    }

    return response.withBody(observed());
  }

  void _ensureAvailable() {
    if (_isDisposed) throw StateError('This client has been disposed.');
    if (_isTransportAvailable?.call() == false) {
      throw StateError('The transport owner has been closed.');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
  }
}
