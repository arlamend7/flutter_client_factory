import 'dart:convert';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/sse.dart';
import 'package:flutter_client_factory/testing.dart';
import 'package:test/test.dart';

void main() {
  test('SSE retains metadata-only IDs and stops after a 204', () async {
    var attempts = 0;
    final transport = FakeHttpTransport((request, token) async {
      attempts++;
      if (attempts == 1) {
        return HttpResponse.bytes(
            statusCode: 200,
            headers: HttpHeaders({
              'content-type': ['text/event-stream']
            }),
            bytes: utf8.encode('id: checkpoint\nretry: 0\n\ndata: hello\n\n'));
      }
      expect(request.headers['last-event-id'], ['checkpoint']);
      return HttpResponse.bytes(statusCode: 204);
    });
    final client = HttpClientService(transport: transport);
    final events = await ServerSentEventsClient(client)
        .connect(Uri.parse('https://example.invalid/events'))
        .toList();
    expect(events.map((event) => event.data), ['hello']);
    expect(attempts, 2);
    client.dispose();
    await transport.close();
  });
  test('SSE rejects non-event response types and releases them', () async {
    var closed = false;
    final transport = FakeHttpTransport((request, token) async => HttpResponse(
        statusCode: 200,
        body: const Stream.empty(),
        onClose: () {
          closed = true;
        }));
    final client = HttpClientService(transport: transport);
    await expectLater(
        ServerSentEventsClient(client)
            .connect(Uri.parse('https://example.invalid/'))
            .toList(),
        throwsStateError);
    expect(closed, isTrue);
    client.dispose();
    await transport.close();
  });
}
