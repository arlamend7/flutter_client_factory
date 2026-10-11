import 'dart:async';

import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/testing.dart';
import 'package:test/test.dart';

void main() {
  test(
      'waitForOne observes async middleware, flushes JSON and verifies completion',
      () async {
    final controller = HttpTestingController();
    addTearDown(controller.close);
    final gate = Completer<void>();
    final client = controller
        .createClient(baseUrl: 'https://test.invalid/', interceptors: [
      (request, token, next) async {
        await gate.future;
        return next(request.withHeader('Authorization', 'Bearer test'), token);
      },
    ]);
    final response = client.getAsync('users');
    final waiting = controller.waitForOne('https://test.invalid/users',
        method: HttpMethod.get);
    controller.expectNone('https://test.invalid/users');
    gate.complete();
    final request = await waiting;
    expect(request.request.headers['authorization'], ['Bearer test']);
    expect(controller.verify, throwsStateError);
    request.flushJson({'name': 'Ada'}, statusCode: 201);
    final result = await response;
    expect(result.statusCode, 201);
    expect(result.headers['content-type'].single, contains('application/json'));
    expect(
        await result.readJson(decode: (json) => (json as Map)['name']), 'Ada');
    controller.verify();
    expect(() => request.flushText('again'), throwsStateError);
  });

  test(
      'matching filters method and reports candidates without losing duplicates',
      () async {
    final controller = HttpTestingController();
    addTearDown(controller.close);
    final client = controller.createClient();
    const url = 'https://test.invalid/users';
    final first = client.getAsync(url);
    final second = client.getAsync(url);
    final post = client.postAsync(url);
    expect(
        () => controller.expectOne(url),
        throwsA(isA<StateError>().having(
            (error) => error.message, 'diagnostic', contains('POST $url'))));
    final posted = controller.expectOne(url, method: HttpMethod.post);
    posted.flushText('denied',
        statusCode: 403, headers: {'Content-Type': 'text/custom'});
    final postedResponse = await post;
    expect(postedResponse.statusCode, 403);
    expect(postedResponse.headers['content-type'], ['text/custom']);
    expect(await postedResponse.readText(), 'denied');
    await expectLater(controller.waitForOne(url), throwsStateError);
    for (final item
        in controller.match((request) => request.method == HttpMethod.get)) {
      item.flushJson(null);
    }
    expect(await (await first).readJson(decode: (json) => json), isNull);
    expect(await (await second).readText(), 'null');
    controller.verify();
  });

  test('waiting has bounded failure, predicate failure, and shutdown cleanup',
      () async {
    final controller = HttpTestingController();
    final client = controller.createClient();
    await expectLater(
        controller.waitForOne('https://test.invalid/missing',
            timeout: const Duration(milliseconds: 10)),
        throwsA(isA<TimeoutException>()));
    final response = client.getAsync('https://test.invalid/');
    await expectLater(
        controller.waitForOneWhere((_) => throw StateError('predicate')),
        throwsStateError);
    controller.expectOneWhere((_) => true).flushText('ok');
    await (await response).dispose();
    final waiting = controller.waitForOne('https://test.invalid/missing');
    final assertion = expectLater(waiting, throwsStateError);
    await controller.close();
    await assertion;
    await expectLater(
        controller.waitForOne('https://test.invalid/'), throwsStateError);
    expect(() => controller.createClient(), throwsStateError);
  });
}
