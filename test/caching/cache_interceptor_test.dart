import 'package:flutter_client_factory/caching.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:test/test.dart';

void main() {
  test('cache validates stale ETags and bypasses authentication', () async {
    var clock = DateTime.utc(2026);
    final cache = CacheInterceptor(MemoryCacheStore(), clock: () => clock);
    final request = HttpRequest(uri: Uri.parse('https://example.invalid/data'));
    var sends = 0;
    Future<HttpResponse> next(HttpRequest r, CancellationToken t) async {
      sends++;
      if (r.headers.contains('if-none-match')) {
        expect(r.headers['if-none-match'], ['"one"']);
        return HttpResponse.bytes(
            statusCode: 304,
            headers: HttpHeaders({
              'cache-control': ['max-age=60']
            }));
      }
      return HttpResponse.bytes(
          statusCode: 200,
          bytes: [1, 2],
          headers: HttpHeaders({
            'content-length': ['2'],
            'cache-control': ['max-age=1'],
            'etag': ['"one"']
          }));
    }

    for (var i = 0; i < 2; i++) {
      final response =
          await cache.intercept(request, CancellationToken(), next);
      expect(await const ResponseBodyReader().readBytes(response), [1, 2]);
    }
    expect(sends, 1);
    clock = clock.add(const Duration(seconds: 2));
    final validated = await cache.intercept(request, CancellationToken(), next);
    expect(await const ResponseBodyReader().readBytes(validated), [1, 2]);
    expect(sends, 2);
    final privateResponse = await cache.intercept(
        request.copyWith(
            headers: HttpHeaders({
          'authorization': ['secret']
        })),
        CancellationToken(),
        next);
    await privateResponse.dispose();
    expect(sends, 3);
  });
}
