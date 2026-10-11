import 'dart:convert';

import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:test/test.dart';

void main() {
  test('form conveniences preserve encoding, repeats, length and snapshots',
      () async {
    final bytes = [1, 2, 3];
    final fields = {'name': 'Ada'};
    final form = FormData(fields: fields, files: [
      MultipartPart.bytes(name: 'avatar', filename: 'avatar.bin', bytes: bytes),
    ], parts: [
      MultipartPart.text(name: 'name', value: 'Lovelace')
    ]);
    fields.clear();
    bytes.clear();
    final encoded = await form.openRead().expand((chunk) => chunk).toList();
    expect(encoded.length, form.contentLength);
    expect(form.isReplayable, isTrue);
    expect(await form.openRead().expand((chunk) => chunk).toList(), encoded);
    final text = latin1.decode(encoded);
    expect(text, contains('name="name"'));
    expect(text, contains('Ada'));
    expect(text, contains('Lovelace'));
    expect(text, contains('filename="avatar.bin"'));
    expect(form.contentType, contains('boundary=${form.boundary}'));
    expect(
        await utf8.decoder
            .bind(FormRequestBody.single({'a b': 'x&y'}).openRead())
            .join(),
        'a+b=x%26y');
  });

  test(
      'multipart rejects header injection and retains one-shot stream semantics',
      () async {
    expect(() => MultipartPart.bytes(name: 'bad\r\nname', bytes: []),
        throwsArgumentError);
    final form = FormData(parts: [
      MultipartPart(name: 'stream', body: StreamRequestBody(Stream.value([1])))
    ]);
    expect(form.isReplayable, isFalse);
    expect(form.contentLength, isNull);
    await form.openRead().drain<void>();
    await expectLater(form.openRead().drain<void>(), throwsStateError);
  });
}
