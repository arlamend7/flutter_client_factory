import 'dart:convert';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/testing.dart';
import 'package:test/test.dart';
import '../../example/lib/models/example_user.dart';
import '../../example/lib/models/login_result.dart';
import '../../example/lib/services/authentication_service.dart';
import '../../example/lib/services/user_service.dart';

void main() {
  late HttpTestingController testing;
  late HttpClient client;
  late UserService users;
  setUp(() {
    testing = HttpTestingController();
    client = testing.createClient(
        baseUrl: 'https://example.test/api/',
        defaultHeaders: {'Accept': 'application/json'});
    users = UserService(client: client);
  });
  tearDown(() async {
    try {
      testing.verify();
    } finally {
      client.dispose();
      await testing.close();
    }
  });

  test('caller validates status and decodes a custom model', () async {
    final pending = users.getUser(1);
    final request =
        await testing.waitForOne('https://example.test/api/users/1');
    expect(request.request.headers['accept'], ['application/json']);
    request.flushJson({'id': 1, 'name': 'Ada'});
    final response = await pending;
    expect(response.isSuccessful, isTrue);
    final user = await response.readJson(decode: ExampleUser.fromJson);
    expect(user.name, 'Ada');
  });

  test('caller reads raw text without JSON conversion', () async {
    final pending = users.getUser(1);
    (await testing.waitForOne('https://example.test/api/users/1'))
        .flushText('Hello Ada');
    final response = await pending;
    expect(await response.readText(), 'Hello Ada');
  });

  test('HTTP failure is returned and can be discarded without decoding',
      () async {
    var closed = false;
    final pending = users.getUser(1);
    (await testing.waitForOne('https://example.test/api/users/1'))
        .flush(HttpResponse(
            statusCode: 404,
            body: const Stream.empty(),
            onClose: () {
              closed = true;
            }));
    final response = await pending;
    expect(response.isSuccessful, isFalse);
    await response.dispose();
    expect(closed, isTrue);
  });

  test('invalid model payload fails decoding and releases response', () async {
    var closed = false;
    final pending = users.getUser(1);
    (await testing.waitForOne('https://example.test/api/users/1'))
        .flush(HttpResponse(
            statusCode: 200,
            body: Stream.value(utf8.encode('{"id":"invalid"}')),
            onClose: () {
              closed = true;
            }));
    final response = await pending;
    await expectLater(
        response.readJson(decode: ExampleUser.fromJson), throwsFormatException);
    expect(closed, isTrue);
  });

  test('service encodes a query and forwards cancellation', () async {
    final token = CancellationToken();
    final pending =
        users.findUsers('ada+work@example.test', cancellationToken: token);
    final failure =
        expectLater(pending, throwsA(isA<RequestCanceledException>()));
    final request = await testing
        .waitForOneWhere((request) => request.uri.path == '/api/users');
    expect(
        request.request.uri.queryParameters['email'], 'ada+work@example.test');
    token.cancel('Screen closed');
    await failure;
  });

  test('sign-in service sends JSON and caller decodes nested values', () async {
    final authentication = AuthenticationService(client: client);
    final pending =
        authentication.login('ada@example.test', 'example-password');
    final request =
        await testing.waitForOne('https://example.test/api/auth/login');
    expect(request.request.method, HttpMethod.post);
    expect(request.request.uri.queryParameters, isEmpty);
    final body = await request.request.body!
        .openRead()
        .expand((bytes) => bytes)
        .toList();
    expect(jsonDecode(utf8.decode(body)),
        {'email': 'ada@example.test', 'password': 'example-password'});
    request.flushJson({
      'token': 'example-token',
      'user': {'id': 1, 'name': 'Ada'}
    });
    final response = await pending;
    final result = await response.readJson(decode: LoginResult.fromJson);
    expect(result.token, 'example-token');
    expect(result.user.name, 'Ada');
  });

  test('login model rejects missing credentials or invalid user payload', () {
    expect(() => LoginResult.fromJson({'token': ''}), throwsFormatException);
    expect(() => LoginResult.fromJson({'token': 'example-token', 'user': null}),
        throwsFormatException);
  });

  for (final method in [HttpMethod.post, HttpMethod.put]) {
    test('service sends a model with ${method.value}', () async {
      const user = ExampleUser(id: 1, name: 'Ada');
      final pending = method == HttpMethod.post
          ? users.createUser(user)
          : users.updateUser(user);
      final request =
          await testing.waitForOneWhere((request) => request.method == method);
      expect(request.request.body!.contentType, contains('application/json'));
      expect(
          jsonDecode(utf8.decode(await request.request.body!
              .openRead()
              .expand((bytes) => bytes)
              .toList())),
          user.toJson());
      request.flushJson(user.toJson());
      await (await pending).dispose();
    });
  }
}
