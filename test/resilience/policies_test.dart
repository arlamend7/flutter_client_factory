import 'dart:async';

import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/resilience.dart';
import 'package:test/test.dart';

void main() {
  final request = HttpRequest(uri: Uri.parse('https://example.invalid/'));
  test('retry drains unsuccessful responses, honors budget and Retry-After',
      () async {
    final waits = <Duration>[];
    var sends = 0;
    var disposed = 0;
    final retry = RetryInterceptor(
        options: RetryOptions(maxAttempts: 3),
        random: () => 1,
        delay: (delay, token) async {
          waits.add(delay);
        });
    final response =
        await retry.intercept(request, CancellationToken(), (r, t) async {
      sends++;
      return HttpResponse(
          statusCode: sends == 3 ? 200 : 503,
          body: const Stream.empty(),
          headers: HttpHeaders({
            'retry-after': ['1']
          }),
          onClose: () {
            disposed++;
          });
    });
    expect(sends, 3);
    expect(disposed, 2);
    expect(waits, [const Duration(seconds: 1), const Duration(seconds: 1)]);
    await response.dispose();
  });
  test('writes and one-shot uploads do not automatically retry', () async {
    final retry = RetryInterceptor();
    var sends = 0;
    final response = await retry.intercept(
        request.copyWith(method: HttpMethod.post), CancellationToken(),
        (r, t) async {
      sends++;
      return HttpResponse.bytes(statusCode: 503);
    });
    expect(sends, 1);
    await response.dispose();
  });
  test('timeout aborts response bodies and distinguishes cancellation',
      () async {
    final controller = StreamController<List<int>>();
    var disposed = false;
    final response =
        await TimeoutInterceptor(const Duration(milliseconds: 20)).intercept(
            request,
            CancellationToken(),
            (r, t) async => HttpResponse(
                statusCode: 200,
                body: controller.stream,
                onClose: () {
                  disposed = true;
                }));
    await expectLater(const ResponseBodyReader().readBytes(response),
        throwsA(isA<RequestTimeoutException>()));
    expect(disposed, isTrue);
    await controller.close();
  });
  test('canceling a queued operation removes it before dispatch', () async {
    final limiter = ConcurrencyInterceptor(maxConcurrent: 1);
    var sends = 0;
    Future<HttpResponse> next(HttpRequest r, CancellationToken t) async {
      sends++;
      return HttpResponse.bytes(statusCode: 200);
    }

    final first = await limiter.intercept(request, CancellationToken(), next);
    final token = CancellationToken();
    final pending = limiter.intercept(request, token, next);
    final assertion =
        expectLater(pending, throwsA(isA<RequestCanceledException>()));
    token.cancel();
    await assertion;
    await first.dispose();
    final third = await limiter.intercept(request, CancellationToken(), next);
    expect(sends, 2);
    await third.dispose();
  });
  test('circuit opens, waits for cooldown and accepts a successful probe',
      () async {
    var clock = DateTime.utc(2026);
    final circuit = CircuitBreakerInterceptor(
        failureThreshold: 1,
        clock: () => clock,
        breakDuration: const Duration(seconds: 1));
    final failure = await circuit.intercept(request, CancellationToken(),
        (r, t) async => HttpResponse.bytes(statusCode: 503));
    await failure.dispose();
    await expectLater(
        circuit.intercept(request, CancellationToken(),
            (r, t) async => HttpResponse.bytes(statusCode: 200)),
        throwsA(isA<CircuitOpenException>()));
    clock = clock.add(const Duration(seconds: 2));
    final success = await circuit.intercept(request, CancellationToken(),
        (r, t) async => HttpResponse.bytes(statusCode: 200));
    expect(success.isSuccessful, isTrue);
    await success.dispose();
  });
}
