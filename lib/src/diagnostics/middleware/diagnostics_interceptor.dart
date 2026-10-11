import '../../core/cancellation/cancellation_token.dart';
import '../../http/middleware/contracts/http_middleware.dart';
import '../../http/middleware/contracts/http_request_handler.dart';
import '../../http/models/http_request.dart';
import '../../http/models/http_response.dart';
import '../services/header_redactor.dart';

/// Reports request, headers and failure metadata without body or query contents.
/// Extend header redaction for application-specific secrets before enabling logging.
class DiagnosticsInterceptor implements HttpMiddleware {
  DiagnosticsInterceptor(this.write, {HeaderRedactor? redactor})
      : redactor = redactor ?? HeaderRedactor();
  final void Function(Map<String, Object?> event) write;
  final HeaderRedactor redactor;
  @override
  Future<HttpResponse> intercept(HttpRequest request, CancellationToken token,
      HttpRequestHandler next) async {
    final watch = Stopwatch()..start();
    write({
      'phase': 'request',
      'method': request.method.value,
      'url': '${request.uri.origin}${request.uri.path}',
      'headers': redactor.redact(request.headers)
    });
    try {
      final response = await next(request, token);
      try {
        write({
          'phase': 'headers',
          'status': response.statusCode,
          'elapsedMicroseconds': watch.elapsedMicroseconds
        });
      } catch (_) {
        await response.dispose();
        rethrow;
      }
      return response;
    } catch (error) {
      write({
        'phase': 'failure',
        'errorType': error.runtimeType.toString(),
        'elapsedMicroseconds': watch.elapsedMicroseconds
      });
      rethrow;
    }
  }
}
