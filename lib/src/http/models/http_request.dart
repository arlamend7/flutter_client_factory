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
    RequestContext? context,
  })  : headers = headers ?? HttpHeaders(),
        context = context ?? RequestContext();

  final Uri uri;
  final HttpMethod method;
  final HttpHeaders headers;
  final RequestBody? body;
  final RequestContext context;

  /// Copies selected values; [removeBody] explicitly clears an existing body.
  HttpRequest copyWith({
    Uri? uri,
    HttpMethod? method,
    HttpHeaders? headers,
    RequestBody? body,
    bool removeBody = false,
    RequestContext? context,
  }) {
    return HttpRequest(
      uri: uri ?? this.uri,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      body: removeBody ? null : body ?? this.body,
      context: context ?? this.context,
    );
  }
}
