import 'dart:convert';
import 'package:flutter_client_factory/caching.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:test/test.dart';

void main() {
  final request = HttpRequest(uri: Uri.parse('https://example.invalid/value'));
  test('Vary rejects a representation for another request header', () async {
    final cache = CacheInterceptor(MemoryCacheStore());
    var calls = 0;
    Future<HttpResponse> send(
        HttpRequest request, CancellationToken token) async {
      calls++;
      return HttpResponse.bytes(
          statusCode: 200,
          bytes: utf8.encode(request.headers['accept-language'].single),
          headers: HttpHeaders({
            'cache-control': ['max-age=100'],
            'content-length': ['2'],
            'vary': ['accept-language'],
          }));
    }

    for (final language in ['en', 'en', 'fr']) {
      final response = await cache.intercept(
          request.copyWith(
              headers: HttpHeaders({
            'accept-language': [language]
          })),
          CancellationToken(),
          send);
      expect(await const ResponseBodyReader().readText(response), language);
    }
    expect(calls, 2);
  });
  test('LRU cache stays within its byte budget', () async {
    final store = MemoryCacheStore(maxBytes: 4);
    CacheEntry entry(int value) => CacheEntry(
        response: BufferedHttpResponse(
            statusCode: 200, bytes: [value, value], headers: HttpHeaders()),
        expiresAt: DateTime.utc(2100),
        vary: {});
    await store.write('a', entry(1));
    await store.write('b', entry(2));
    await store.read('a');
    await store.write('c', entry(3));
    expect(await store.read('b'), isNull);
    expect(await store.read('a'), isNotNull);
    await store.clear();
    expect(await store.read('a'), isNull);
  });
  test('Set-Cookie and unknown lengths never populate the cache', () async {
    final store = MemoryCacheStore();
    final cache = CacheInterceptor(store);
    for (final headers in [
      HttpHeaders({
        'cache-control': ['max-age=60']
      }),
      HttpHeaders({
        'cache-control': ['max-age=60'],
        'content-length': ['0'],
        'set-cookie': ['session=private']
      })
    ]) {
      final response = await cache.intercept(
          request,
          CancellationToken(),
          (_, __) async =>
              HttpResponse.bytes(statusCode: 200, headers: headers));
      await response.dispose();
      expect(await store.read(request.uri.toString()), isNull);
    }
  });
}
