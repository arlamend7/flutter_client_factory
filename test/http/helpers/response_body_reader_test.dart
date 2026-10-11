import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_client/flutter_client.dart';
import 'package:test/test.dart';

void main() {
  test('bounded buffering releases an oversized response exactly once',
      () async {
    var closed = 0;
    final response = HttpResponse(
        statusCode: 200,
        body: Stream.value([1, 2, 3]),
        onClose: () {
          closed++;
        });
    await expectLater(const ResponseBodyReader(maxBytes: 2).readBytes(response),
        throwsStateError);
    await response.dispose();
    expect(closed, 1);
  });
  test(
      'byte snapshots are compact, immutable and isolated from source mutation',
      () async {
    final source = [1, 2, 3];
    final response = HttpResponse.bytes(statusCode: 200, bytes: source);
    source[0] = 9;
    final bytes = await const ResponseBodyReader().readBytes(response);
    expect(bytes, isA<Uint8List>());
    expect(bytes, [1, 2, 3]);
    expect(() => bytes[0] = 4, throwsUnsupportedError);
  });
  test('malformed JSON releases the response before decoder failure escapes',
      () async {
    var closed = false;
    final response = HttpResponse(
        statusCode: 200,
        body: Stream.value([123]),
        onClose: () {
          closed = true;
        });
    await expectLater(
        const ResponseBodyReader().readJson<Object?>(response, (json) => json),
        throwsFormatException);
    expect(closed, isTrue);
  });
  test('dispose before listening releases a streaming source', () async {
    var canceled = false;
    final source = StreamController<List<int>>(onCancel: () {
      canceled = true;
    });
    final response = HttpResponse(statusCode: 200, body: source.stream);
    await response.dispose();
    await source.close();
    expect(canceled, isTrue);
  });
}
