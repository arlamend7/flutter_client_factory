import 'package:flutter_client_factory/authentication.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/resilience.dart';
import 'package:flutter_client_factory/testing.dart';
import 'package:test/test.dart';

import '../../fixtures/counting_token_provider.dart';

void main() {
  final request = HttpRequest(uri: Uri.parse('https://example.invalid/'));

  test('retry and authentication repeat only downstream interceptors',
      () async {
    final events = <String>[];
    final statuses = [503, 401, 200];
    var sends = 0;
    var released = 0;
    final provider = CountingTokenProvider();
    final coordinator = TokenRefreshCoordinator(provider);
    final authentication = AuthenticationInterceptor(
      coordinator: coordinator,
      allowedOrigins: {'https://example.invalid'},
    );
    final retry = RetryInterceptor(delay: (_, __) async {});
    final transport = FakeHttpTransport((request, token) async {
      final status = statuses[sends++];
      events.add('transport $status');
      expect(released, sends - 1);
      return HttpResponse(
        statusCode: status,
        body: const Stream.empty(),
        onClose: () {
          released++;
        },
      );
    });
    final client = HttpClientService(
      transport: transport,
      options: HttpClientOptions(
        onEvent: (event) {
          if (event is RequestSentEvent) events.add('sent');
        },
        interceptors: [
          (request, token, next) async {
            events.add('operation start');
            final response = await next(request, token);
            events.add('operation end');
            return response;
          },
          retry.intercept,
          (request, token, next) async {
            events.add('retry start');
            final response = await next(request, token);
            events.add('retry end');
            return response;
          },
          authentication.intercept,
          (request, token, next) async {
            events.add('send ${request.headers['authorization'].single}');
            final response = await next(request, token);
            events.add('received ${response.statusCode}');
            return response;
          },
        ],
      ),
    );
    addTearDown(transport.close);
    addTearDown(coordinator.dispose);
    addTearDown(client.dispose);

    final response = await client.send(request);
    expect(response.statusCode, 200);
    expect(provider.refreshes, 1);
    expect(events, [
      'operation start',
      'retry start',
      'send Bearer old',
      'sent',
      'transport 503',
      'received 503',
      'retry end',
      'retry start',
      'send Bearer old',
      'sent',
      'transport 401',
      'received 401',
      'send Bearer new',
      'sent',
      'transport 200',
      'received 200',
      'retry end',
      'operation end',
    ]);
    expect(released, 2);
    await response.dispose();
    expect(released, 3);
  });

  test('timeout after retry gets a fresh scope linked to the overall token',
      () async {
    final attempts = <CancellationToken>[];
    late CancellationToken overall;
    final parent = CancellationToken();
    final transport = FakeHttpTransport((request, token) async {
      attempts.add(token);
      return HttpResponse.bytes(statusCode: attempts.length == 1 ? 503 : 200);
    });
    final client = HttpClientService(
      transport: transport,
      options: HttpClientOptions(interceptors: [
        TimeoutInterceptor(const Duration(seconds: 30)).intercept,
        (request, token, next) {
          overall = token;
          return next(request, token);
        },
        RetryInterceptor(delay: (_, __) async {}).intercept,
        TimeoutInterceptor(const Duration(seconds: 10)).intercept,
      ]),
    );
    addTearDown(transport.close);
    addTearDown(client.dispose);
    addTearDown(parent.dispose);

    final response = await client.send(request, cancellationToken: parent);
    addTearDown(response.dispose);
    expect(attempts, hasLength(2));
    expect(identical(attempts.first, attempts.last), isFalse);
    expect(identical(overall, attempts.last), isFalse);

    parent.cancel();
    expect(overall.isCanceled, isTrue);
    expect(attempts.last.isCanceled, isTrue);
    expect(attempts.first.isCanceled, isFalse);
    await expectLater(const ResponseBodyReader().readBytes(response),
        throwsA(isA<RequestCanceledException>()));
  });

  for (final disposeClient in [false, true]) {
    test('checks ${disposeClient ? 'disposal' : 'cancellation'} on resend',
        () async {
      var sentEvents = 0;
      final transport = FakeHttpTransport(
        (request, token) async => HttpResponse.bytes(statusCode: 503),
      );
      late HttpClientService client;
      client = HttpClientService(
        transport: transport,
        options: HttpClientOptions(
          onEvent: (event) {
            if (event is RequestSentEvent) sentEvents++;
          },
          interceptors: [
            (request, token, next) async {
              final response = await next(request, token);
              await response.dispose();
              if (disposeClient) {
                client.dispose();
              } else {
                token.cancel();
              }
              return next(request, token);
            },
          ],
        ),
      );
      addTearDown(transport.close);
      addTearDown(client.dispose);

      await expectLater(
        client.send(request),
        throwsA(disposeClient
            ? isA<StateError>()
            : isA<RequestCanceledException>()),
      );
      expect(transport.requests, hasLength(1));
      expect(sentEvents, 1);
    });
  }
}
