import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/testing.dart';
import 'package:test/test.dart';

void main() {
  test('named settings configure lazy shared transports and their lifetime',
      () async {
    var clock = DateTime.utc(2026);
    final transports = <FakeHttpTransport>[];
    final events = <HttpEvent>[];
    final HttpClientFactory factory =
        DefaultHttpClientFactory(clock: () => clock);
    addTearDown(factory.close);
    factory.registerClient(
      'api',
      baseUrl: 'https://example.invalid/api/',
      defaultHeaders: {'Accept': 'application/json'},
      interceptors: [
        (request, token, next) => next(
              request.copyWith(
                headers: request.headers.withValue('x-policy', 'applied'),
              ),
              token,
            ),
      ],
      transportLifetime: const Duration(seconds: 1),
      createTransport: () {
        final transport = FakeHttpTransport((request, token) async {
          expect(request.uri.toString(), 'https://example.invalid/api/users');
          expect(request.headers['accept'], ['application/json']);
          expect(request.headers['x-policy'], ['applied']);
          return HttpResponse.bytes(statusCode: 200);
        });
        transports.add(transport);
        return transport;
      },
      onEvent: events.add,
    );
    final first = factory.create('api');
    final second = factory.create('api');
    expect(transports, isEmpty);
    final request = HttpRequest(uri: Uri.parse('users'));
    await (await first.send(request)).dispose();
    await (await second.send(request)).dispose();
    expect(transports, hasLength(1));

    clock = clock.add(const Duration(seconds: 2));
    await (await first.send(request)).dispose();
    expect(transports, hasLength(2));
    expect(events.whereType<RequestSentEvent>(), hasLength(3));
    await factory.close();
    expect(transports.every((transport) => transport.isClosed), isTrue);
  });

  test('callback overrides defaults once and freezes copies of configuration',
      () async {
    final factory = DefaultHttpClientFactory();
    addTearDown(factory.close);
    var configurations = 0;
    final order = <String>[];
    final events = <HttpEvent>[];
    final headers = {'Accept': 'text/plain'};
    final interceptors = <HttpInterceptor>[
      (request, token, next) {
        order.add('named');
        return next(request, token);
      },
    ];
    final transport = FakeHttpTransport((request, token) async {
      expect(request.uri.toString(), 'https://configured.invalid/v1/users');
      expect(request.headers['accept'], ['application/json']);
      expect(request.headers['x-app-version'], ['1.0']);
      return HttpResponse.bytes(statusCode: 200);
    });
    late HttpClientRegistrationBuilder captured;
    factory.registerClient(
      'api',
      baseUrl: 'https://original.invalid/',
      defaultHeaders: headers,
      interceptors: interceptors,
      createTransport: () => throw StateError('Must be overridden'),
      onEvent: (_) => fail('Must use the callback observer'),
      configure: (client) {
        configurations++;
        captured = client;
        client.baseUrl = 'https://configured.invalid/v1/';
        client.defaultHeaders['accept'] = 'application/json';
        client.defaultHeaders['X-App-Version'] = '1.0';
        client.interceptors.add((request, token, next) {
          order.add('callback');
          return next(request, token);
        });
        client.createTransport = () => transport;
        client.onEvent = events.add;
      },
    );
    expect(headers, {'Accept': 'text/plain'});
    expect(interceptors, hasLength(1));
    headers.clear();
    interceptors.clear();
    captured.defaultHeaders.clear();
    captured.interceptors.clear();
    captured.baseUrl = 'invalid';
    captured.createTransport = () => throw StateError('Snapshot was mutated');
    captured.onEvent = null;

    for (var i = 0; i < 2; i++) {
      final client = factory.create('api');
      await (await client.send(HttpRequest(uri: Uri.parse('users')))).dispose();
    }
    expect(configurations, 1);
    expect(order, ['named', 'callback', 'named', 'callback']);
    expect(events.whereType<RequestSentEvent>(), hasLength(2));
  });

  test('callback failure leaves no registration and builds no transport', () {
    final factory = DefaultHttpClientFactory();
    addTearDown(factory.close);
    expect(
      () => factory.registerClient(
        'api',
        createTransport: () => throw StateError('Must remain lazy'),
        configure: (_) => throw const FormatException('Invalid app config'),
      ),
      throwsFormatException,
    );
    expect(() => factory.create('api'), throwsStateError);
    factory.registerClient('api');
    expect(factory.create('api'), isA<HttpClient>());
    expect(() => factory.registerClient('api'), throwsStateError);
  });

  final invalidSettings =
      <String, void Function(HttpClientRegistrationBuilder)>{
    'relative base URL': (client) => client.baseUrl = '/api/',
    'non-HTTP URL': (client) => client.baseUrl = 'ftp://example.invalid/',
    'embedded credentials': (client) =>
        client.baseUrl = 'https://user:password@example.invalid/',
    'non-positive lifetime': (client) =>
        client.transportLifetime = Duration.zero,
    'invalid header': (client) =>
        client.defaultHeaders['Accept'] = 'bad\r\nvalue',
  };
  for (final entry in invalidSettings.entries) {
    test('rejects ${entry.key} before registering', () {
      final factory = DefaultHttpClientFactory();
      addTearDown(factory.close);
      expect(
        () => factory.registerClient('api', configure: entry.value),
        throwsArgumentError,
      );
      expect(() => factory.create('api'), throwsStateError);
    });
  }
}
