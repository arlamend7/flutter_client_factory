import '../../../core/cancellation/cancellation_token.dart';
import '../../../core/errors/network_exception.dart';
import '../../../core/errors/request_timeout_exception.dart';
import '../../../http/enums/http_method.dart';
import '../../../http/middleware/contracts/http_middleware.dart';
import '../../../http/middleware/contracts/http_request_handler.dart';
import '../../../http/models/http_request.dart';
import '../../../http/models/http_response.dart';

/// Explicit alternate origins for replayable reads; credentials never cross origins.
class FailoverInterceptor implements HttpMiddleware {
  FailoverInterceptor(Iterable<Uri> origins)
      : origins = List.unmodifiable(origins) {
    if (this.origins.any((uri) =>
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty)) {
      throw ArgumentError('Invalid failover origins.');
    }
  }
  final List<Uri> origins;
  @override
  Future<HttpResponse> intercept(HttpRequest request, CancellationToken token,
      HttpRequestHandler next) async {
    if (!{HttpMethod.get, HttpMethod.head, HttpMethod.options}
            .contains(request.method) ||
        request.body?.isReplayable == false) {
      return next(request, token);
    }
    final destinations = [
      request.uri,
      ...origins.map((origin) => request.uri
          .replace(scheme: origin.scheme, host: origin.host, port: origin.port))
    ];
    for (var index = 0;; index++) {
      token.throwIfCanceled();
      final target = destinations[index];
      final outgoing = request.copyWith(
          uri: target,
          headers: target.origin == request.uri.origin
              ? request.headers
              : request.headers
                  .without(['authorization', 'proxy-authorization', 'cookie']));
      try {
        final response = await next(outgoing, token);
        if (index == destinations.length - 1 || response.statusCode < 500) {
          return response;
        }
        await response.dispose();
      } catch (error) {
        if (token.isCanceled ||
            index == destinations.length - 1 ||
            (error is! NetworkException && error is! RequestTimeoutException)) {
          rethrow;
        }
      }
    }
  }
}
