import '../events/models/http_event.dart';
import '../middleware/contracts/http_interceptor.dart';
import '../models/http_headers.dart';

/// A snapshot of logical client configuration.
class HttpClientOptions {
  HttpClientOptions({
    this.baseUri,
    this.onEvent,
    this.timeout,
    HttpHeaders? headers,
    List<HttpInterceptor> interceptors = const <HttpInterceptor>[],
  })  : headers = headers ?? HttpHeaders(),
        interceptors = List<HttpInterceptor>.unmodifiable(interceptors) {
    if (timeout != null && timeout! <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive');
    }
  }

  /// Default overall deadline; null leaves requests without an overall deadline.
  /// Per-request values override this, but independent middleware still applies.
  final Duration? timeout;
  final Uri? baseUri;
  final void Function(HttpEvent)? onEvent;

  final HttpHeaders headers;

  /// One outermost-first pipeline; responses unwind in reverse order.
  ///
  /// Interceptors that resend a request repeat only the downstream pipeline.
  /// Place a policy before retry/auth refresh to surround its work, or after it
  /// to run again on each resend. Place per-send policies after all resenders.
  final List<HttpInterceptor> interceptors;
}
