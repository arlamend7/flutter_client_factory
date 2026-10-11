import 'package:flutter_client/flutter_client.dart';
import 'package:flutter_client/testing.dart';
import 'package:test/test.dart';

void main() {
  test('observation makes one send and reports consumed bytes in order',
      () async {
    final events = <HttpEvent>[];
    final transport = FakeHttpTransport((request, token) async {
      await request.body!.openRead().drain<void>();
      return HttpResponse.bytes(statusCode: 200, bytes: [4, 5]);
    });
    final client = HttpClientService(
        transport: transport, options: HttpClientOptions(onEvent: events.add));
    final response = await client.send(HttpRequest(
        uri: Uri.parse('https://example.invalid/'),
        method: HttpMethod.post,
        body: ByteRequestBody([1, 2, 3])));
    await const ResponseBodyReader().readBytes(response);
    expect(events.map((event) => event.runtimeType), [
      RequestSentEvent,
      UploadProgressEvent,
      ResponseHeadersEvent,
      DownloadProgressEvent,
      ResponseCompletedEvent
    ]);
    expect(transport.requests.length, 1);
    client.dispose();
    await transport.close();
  });
  test('a failing header observer releases the response', () async {
    var closed = false;
    final transport = FakeHttpTransport((request, token) async => HttpResponse(
        statusCode: 200,
        body: const Stream.empty(),
        onClose: () {
          closed = true;
        }));
    final client = HttpClientService(
        transport: transport,
        options: HttpClientOptions(onEvent: (event) {
          if (event is ResponseHeadersEvent) throw StateError('observer');
        }));
    await expectLater(
        client.send(HttpRequest(uri: Uri.parse('https://example.invalid/'))),
        throwsStateError);
    expect(closed, isTrue);
    client.dispose();
    await transport.close();
  });
}
