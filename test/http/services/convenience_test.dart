import 'dart:async';
import 'dart:convert';

import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/resilience.dart';
import 'package:flutter_client_factory/testing.dart';
import 'package:test/test.dart';

void main() {
  test('all verbs use the pipeline with encoded queries and overriding headers',
      () async {
    var intercepted = 0;
    final controller = HttpTestingController();
    addTearDown(controller.close);
    final client = controller
        .createClient(baseUrl: 'https://test.invalid/api/', defaultHeaders: {
      'Accept': 'text/plain'
    }, interceptors: [
      (request, token, next) {
        intercepted++;
        return next(request.withHeader('x-intercepted', 'yes'), token);
      }
    ]);
    final calls = [
      client.getAsync,
      client.postAsync,
      client.putAsync,
      client.patchAsync,
      client.deleteAsync,
      client.headAsync,
      client.optionsAsync
    ];
    for (var i = 0; i < calls.length; i++) {
      final pending =
          calls[i]('users?tag=old&keep=a&keep=b#anchor', queryParameters: {
        'tag': ['a b', 'x&y'],
        'page': 2
      }, headers: {
        'accept': 'application/json'
      });
      final captured = controller
          .expectOneWhere((request) => request.method == HttpMethod.values[i]);
      expect(captured.request.uri.path, '/api/users');
      expect(captured.request.uri.fragment, 'anchor');
      expect(captured.request.uri.queryParametersAll, {
        'tag': ['a b', 'x&y'],
        'keep': ['a', 'b'],
        'page': ['2']
      });
      expect(captured.request.headers['accept'], ['application/json']);
      expect(captured.request.headers['x-intercepted'], ['yes']);
      captured.flushText('ok');
      expect(await (await pending).readText(), 'ok');
    }
    expect(intercepted, calls.length);
    controller.verify();
  });

  test('request extensions retain body context and timeout without mutations',
      () {
    final request = HttpRequest(
        uri: Uri.parse('https://test.invalid/?x=1&x=2&y=3'),
        body: TextRequestBody('original'),
        timeout: const Duration(seconds: 1));
    final modified = request
        .withHeader('Authorization', 'secret')
        .withoutHeader('authorization')
        .withQueryParameters({'x': null, 'z': true});
    expect(identical(modified.body, request.body), isTrue);
    expect(identical(modified.context, request.context), isTrue);
    expect(modified.timeout, request.timeout);
    expect(modified.headers.contains('authorization'), isFalse);
    expect(modified.uri.queryParameters, {'y': '3', 'z': 'true'});
    expect(request.uri.queryParametersAll['x'], ['1', '2']);
    expect(() => request.withQueryParameters({'bad': Object()}),
        throwsArgumentError);
  });

  test('response helpers validate status and release bodies on all exits',
      () async {
    var closed = 0;
    HttpResponse response(int status, List<int> bytes) => HttpResponse(
        statusCode: status,
        body: Stream.value(bytes),
        onClose: () {
          closed++;
        });
    final failure = response(422, utf8.encode('{"error":"invalid"}'));
    expect(await failure.readJson(decode: (json) => (json as Map)['error']),
        'invalid');
    await expectLater(
        response(503, []).requireSuccess(),
        throwsA(isA<HttpStatusException>()
            .having((error) => error.statusCode, 'status', 503)));
    final success = response(200, utf8.encode('text'));
    expect(await success.requireSuccess(), same(success));
    expect(await success.use((current) => current.readText()), 'text');
    await expectLater(
        response(200, []).use<void>((_) => throw StateError('processing')),
        throwsStateError);
    await expectLater(
        response(200, [1, 2]).readBytes(maxBytes: 1), throwsStateError);
    await expectLater(
        response(200, []).readBytes(maxBytes: -1), throwsArgumentError);
    await expectLater(
        response(200, utf8.encode('{')).readJson(decode: (json) => json),
        throwsFormatException);
    final snapshot = await response(200, [1, 2]).buffer();
    expect(await snapshot.toResponse().readBytes(), [1, 2]);
    expect(await snapshot.toResponse().readBytes(), [1, 2]);
    expect(closed, 8);
  });

  test(
      'overall timeout cancels retries during backoff and cleans failed response',
      () async {
    var sends = 0;
    var released = false;
    final factory = DefaultHttpClientFactory();
    addTearDown(factory.close);
    factory.registerClient('api',
        baseUrl: 'https://test.invalid/',
        timeout: const Duration(milliseconds: 30),
        interceptors: [
          RetryInterceptor(
                  delay: (_, token) => token.wait(const Duration(seconds: 5)))
              .intercept
        ],
        createTransport: () => FakeHttpTransport((request, token) async {
              sends++;
              return HttpResponse(
                  statusCode: 503,
                  body: const Stream.empty(),
                  onClose: () {
                    released = true;
                  });
            }));
    await expectLater(factory.create('api').getAsync('users'),
        throwsA(isA<RequestTimeoutException>()));
    expect(sends, 1);
    expect(released, isTrue);
  });

  test('per-request timeout overrides defaults and covers stalled body reads',
      () async {
    final controller = HttpTestingController();
    addTearDown(controller.close);
    final client = controller.createClient(
        baseUrl: 'https://test.invalid/', timeout: const Duration(seconds: 5));
    final pending =
        client.getAsync('users', timeout: const Duration(milliseconds: 30));
    final captured = controller.expectOne('https://test.invalid/users');
    var released = false;
    final body = StreamController<List<int>>();
    captured.flush(HttpResponse(
        statusCode: 200,
        body: body.stream,
        onClose: () {
          released = true;
        }));
    await expectLater(
        (await pending).readBytes(), throwsA(isA<RequestTimeoutException>()));
    expect(captured.token.isCanceled, isTrue);
    expect(released, isTrue);
    await body.close();
    controller.verify();
  });

  test('cancellation keeps its error and late timeout responses are released',
      () async {
    final lateResponse = Completer<HttpResponse>();
    var released = false;
    final transport =
        FakeHttpTransport((request, token) => lateResponse.future);
    addTearDown(transport.close);
    final client = HttpClientService(transport: transport);
    await expectLater(
        client.getAsync('https://test.invalid/',
            timeout: const Duration(milliseconds: 20)),
        throwsA(isA<RequestTimeoutException>()));
    lateResponse.complete(HttpResponse(
        statusCode: 200,
        body: const Stream.empty(),
        onClose: () {
          released = true;
        }));
    await Future<void>.delayed(Duration.zero);
    expect(released, isTrue);
    final controller = HttpTestingController();
    addTearDown(controller.close);
    final token = CancellationToken();
    final pending = controller.createClient().getAsync('https://test.invalid/',
        cancellationToken: token, timeout: const Duration(seconds: 1));
    final assertion =
        expectLater(pending, throwsA(isA<RequestCanceledException>()));
    token.cancel();
    await assertion;
    controller.verify(ignoreCanceled: true);
    expect(() => HttpRequest(uri: Uri(), timeout: Duration.zero),
        throwsArgumentError);
    expect(
        () => HttpClientOptions(timeout: Duration.zero), throwsArgumentError);
  });
}
