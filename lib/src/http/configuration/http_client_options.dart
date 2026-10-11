import '../events/models/http_event.dart';
import '../middleware/contracts/http_interceptor.dart';
import '../models/http_headers.dart';

/// A snapshot of logical client configuration.
class HttpClientOptions {
  HttpClientOptions({
    this.baseUri,
    this.onEvent,
    List<HttpInterceptor> attemptInterceptors = const [],
    HttpHeaders? headers,
    List<HttpInterceptor> interceptors = const <HttpInterceptor>[],
  })  : headers = headers ?? HttpHeaders(),
        attemptInterceptors = List.unmodifiable(attemptInterceptors),
        interceptors = List<HttpInterceptor>.unmodifiable(interceptors);

  final Uri? baseUri;
  final void Function(HttpEvent)? onEvent;

  /// Outermost-first middleware run on each dispatch through the client.
  final List<HttpInterceptor> attemptInterceptors;
  final HttpHeaders headers;

  /// Outermost-first middleware for a logical operation, including all retries.
  final List<HttpInterceptor> interceptors;
}
