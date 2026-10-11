import 'dart:convert';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:test/test.dart';

void main() {
  test('multipart framing and declared length match streamed bytes', () async {
    final body = MultipartRequestBody([
      MultipartPart(
          name: 'file', filename: 'a"b.txt', body: TextRequestBody('hello'))
    ]);
    final bytes = await body.openRead().expand((chunk) => chunk).toList();
    expect(bytes.length, body.contentLength);
    final text = utf8.decode(bytes);
    expect(text, contains('hello\r\n--${body.boundary}--\r\n'));
    expect(text, contains('filename="a\\"b.txt"'));
    expect(
        () => MultipartPart(name: 'bad\r\nheader', body: TextRequestBody('')),
        throwsArgumentError);
  });
}
