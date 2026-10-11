import '../../core/cancellation/cancellation_token.dart';
import '../../http/enums/http_method.dart';
import '../../http/helpers/http_date_codec.dart';
import '../../http/helpers/response_body_reader.dart';
import '../../http/middleware/contracts/http_middleware.dart';
import '../../http/middleware/contracts/http_request_handler.dart';
import '../../http/models/buffered_http_response.dart';
import '../../http/models/http_request.dart';
import '../../http/models/http_response.dart';
import '../contracts/cache_store.dart';
import '../models/cache_entry.dart';

/// Conservative public-response cache. Authenticated/cookie requests bypass it.
class CacheInterceptor implements HttpMiddleware {
  CacheInterceptor(this.store,
      {DateTime Function()? clock, this.maxEntryBytes = 1024 * 1024})
      : _clock = clock ?? DateTime.now;
  final CacheStore store;
  final DateTime Function() _clock;
  final int maxEntryBytes;
  Map<String, String> _directives(List<String> headers) {
    final result = <String, String>{};
    for (final item in headers.join(',').split(',')) {
      final parts = item.trim().split('=');
      result[parts.first.toLowerCase()] =
          parts.length < 2 ? '' : parts[1].replaceAll('"', '');
    }
    return result;
  }

  @override
  Future<HttpResponse> intercept(HttpRequest request, CancellationToken token,
      HttpRequestHandler next) async {
    final key = request.uri.replace(fragment: '').toString();
    if (request.method != HttpMethod.get) {
      final response = await next(request, token);
      if (response.isSuccessful &&
          !{HttpMethod.head, HttpMethod.options}.contains(request.method)) {
        await store.remove(key);
      }
      return response;
    }
    final policy = _directives(request.headers['cache-control']);
    if (request.headers.contains('authorization') ||
        request.headers.contains('cookie') ||
        request.headers.contains('range') ||
        policy.containsKey('no-store')) {
      return next(request, token);
    }
    var cached = await store.read(key);
    if (cached != null &&
        cached.vary.entries.any((entry) =>
            entry.value.join('\u0000') !=
            request.headers[entry.key].join('\u0000'))) {
      cached = null;
    }
    if (cached != null &&
        _clock().isBefore(cached.expiresAt) &&
        !policy.containsKey('no-cache') &&
        policy['max-age'] != '0') {
      return cached.response.toResponse();
    }
    var outgoing = request;
    if (cached != null) {
      final etag = cached.response.headers['etag'];
      final modified = cached.response.headers['last-modified'];
      if (etag.isNotEmpty) {
        outgoing = request.copyWith(
            headers: request.headers.withValue('if-none-match', etag.first));
      } else if (modified.isNotEmpty) {
        outgoing = request.copyWith(
            headers:
                request.headers.withValue('if-modified-since', modified.first));
      }
    }
    var response = await next(outgoing, token);
    if (response.statusCode == 304 && cached != null) {
      await response.dispose();
      response = HttpResponse.bytes(
          statusCode: cached.response.statusCode,
          bytes: cached.response.bytes,
          headers: cached.response.headers.merge(response.headers),
          uri: response.uri);
    }
    final control = _directives(response.headers['cache-control']);
    final vary = response.headers['vary']
        .join(',')
        .split(',')
        .map((name) => name.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toList();
    if (response.statusCode != 200 ||
        control.containsKey('no-store') ||
        control.containsKey('private') ||
        response.headers.contains('set-cookie') ||
        vary.contains('*')) {
      await store.remove(key);
      return response;
    }
    final lengths = response.headers['content-length'];
    final length = lengths.isEmpty ? null : int.tryParse(lengths.first);
    // Unknown or large bodies remain streaming; caching must not force buffering.
    if (length == null || length > maxEntryBytes || length < 0) return response;
    final bytes =
        await ResponseBodyReader(maxBytes: maxEntryBytes).readBytes(response);
    final maxAge = int.tryParse(control['max-age'] ?? '') ?? 0;
    final ages = response.headers['age'];
    var age = ages.isEmpty ? 0 : int.tryParse(ages.first) ?? 0;
    final dates = response.headers['date'];
    final date =
        dates.isEmpty ? null : const HttpDateCodec().parse(dates.first);
    if (date != null && _clock().difference(date).inSeconds > age) {
      age = _clock().difference(date).inSeconds;
    }
    final ttl = control.containsKey('no-cache')
        ? 0
        : (maxAge - age).clamp(0, maxAge < 0 ? 0 : maxAge);
    final buffered = BufferedHttpResponse(
        statusCode: response.statusCode,
        bytes: bytes,
        headers: response.headers,
        uri: response.uri);
    await store.write(
        key,
        CacheEntry(
            response: buffered,
            expiresAt: _clock().add(Duration(seconds: ttl)),
            vary: {for (final name in vary) name: request.headers[name]}));
    return buffered.toResponse();
  }
}
