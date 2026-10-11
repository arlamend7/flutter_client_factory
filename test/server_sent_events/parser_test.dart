import 'dart:convert';

import 'package:flutter_client/sse.dart';
import 'package:test/test.dart';

void main() {
  test('SSE handles fragmented UTF-8, comments, multiline data and metadata',
      () async {
    final bytes = utf8.encode(
        '\uFEFF:comment\r\nid: 7\r\nretry: 1200\r\ndata: café\r\ndata: second\r\n\r\ndata: incomplete');
    final events = await ServerSentEventParser()
        .parse(Stream.fromIterable(bytes.map((byte) => [byte])))
        .toList();
    expect(events.length, 1);
    expect(events.single.data, 'café\nsecond');
    expect(events.single.id, '7');
    expect(events.single.retry, const Duration(milliseconds: 1200));
  });
}
