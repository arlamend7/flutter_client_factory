import '../../core/metadata/request_context.dart';
import '../bodies/request_body.dart';
import '../enums/http_method.dart';
import 'http_headers.dart';

/// Immutable HTTP input. Copying retains the body and its replayability contract.
class HttpRequest {
  HttpRequest({
    required this.uri,
    this.method = HttpMethod.get,
    HttpHeaders? headers,
    this.body,
    this.timeout,
    RequestContext? context,
  })  : headers = headers ?? HttpHeaders(),
        context = context ?? RequestContext() {
    if (timeout != null && timeout! <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive');
    }
  }

  final Uri uri;
  final HttpMethod method;
  final HttpHeaders headers;
  final RequestBody? body;

  /// Overall deadline override, including middleware, retries, and body consumption.
  /// Null inherits the client default. Enforced by HttpClientService.
  final Duration? timeout;
  final RequestContext context;

  /// Copies selected values; [removeBody] explicitly clears an existing body.
  HttpRequest copyWith({
    Uri? uri,
    HttpMethod? method,
    HttpHeaders? headers,
    RequestBody? body,
    bool removeBody = false,
    Duration? timeout,
    RequestContext? context,
  }) {
    return HttpRequest(
      uri: uri ?? this.uri,
      method: method ?? this.method,
      timeout: timeout ?? this.timeout,
      headers: headers ?? this.headers,
      body: removeBody ? null : body ?? this.body,
      context: context ?? this.context,
    );
  }
}
