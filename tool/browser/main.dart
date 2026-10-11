import 'dart:async';
import 'dart:convert';

import 'package:flutter_client/flutter_client.dart';
import 'package:flutter_client/web.dart';
import 'package:flutter_client/websocket_web.dart';

import 'browser_test_body.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  final transport = WebHttpTransport(
      options: WebTransportOptions(xsrfCookieName: 'XSRF-TOKEN'));
  final client = HttpClientService(transport: transport);
  const reader = ResponseBodyReader();
  try {
    final base = Uri.parse(testOrigin);
    final config = await reader.readJson<Map<String, dynamic>>(
        await client.send(HttpRequest(uri: base.resolve('/config'))),
        (json) => json as Map<String, dynamic>);
    final echo = await reader.readJson<Map<String, dynamic>>(
        await client.send(HttpRequest(
            uri: base.resolve('/echo'),
            method: HttpMethod.post,
            body: TextRequestBody('upload'))),
        (json) => json as Map<String, dynamic>);
    check(echo['body'] == 'upload', 'upload body');
    check(echo['xsrf'] == 'test-token', 'same-origin XSRF');
    final cross = await reader.readJson<Map<String, dynamic>>(
        await client.send(HttpRequest(
            uri: Uri.parse(config['cross'] as String).resolve('/echo'),
            method: HttpMethod.post,
            body: TextRequestBody('cross'))),
        (json) => json as Map<String, dynamic>);
    check(cross['xsrf'] == null, 'XSRF must not cross origins');
    final token = CancellationToken();
    final stream = await client.send(HttpRequest(uri: base.resolve('/stream')),
        cancellationToken: token);
    final chunks = <int>[];
    var canceled = false;
    try {
      await for (final chunk in stream.body) {
        chunks.addAll(chunk);
        token.cancel('done');
      }
    } on RequestCanceledException {
      canceled = true;
    }
    check(canceled && utf8.decode(chunks).contains('first'),
        'stream cancellation');
    var uploadReleased = false;
    final stalledUpload = StreamController<List<int>>(onCancel: () {
      uploadReleased = true;
    });
    final uploadToken = CancellationToken();
    final upload = client.send(
        HttpRequest(
            uri: base.resolve('/echo'),
            method: HttpMethod.post,
            body: StreamRequestBody(stalledUpload.stream, contentLength: 1)),
        cancellationToken: uploadToken);
    final cancelUpload =
        Timer(const Duration(milliseconds: 10), uploadToken.cancel);
    try {
      await upload;
      throw StateError('Stalled upload was not canceled.');
    } on RequestCanceledException {
      check(uploadReleased, 'upload source released on cancellation');
    } finally {
      cancelUpload.cancel();
      await stalledUpload.close();
    }
    var mismatchedLength = false;
    try {
      await client.send(HttpRequest(
          uri: base.resolve('/echo'),
          method: HttpMethod.post,
          body: StreamRequestBody(Stream.value([1, 2]), contentLength: 1)));
    } on StateError {
      mismatchedLength = true;
    }
    check(mismatchedLength, 'declared upload length validated');
    final forbidden = HttpRequest(
        uri: base.resolve('/echo'),
        headers: HttpHeaders({
          'host': ['bad']
        }));
    var rejected = false;
    try {
      await client.send(forbidden);
    } on UnsupportedError {
      rejected = true;
    }
    check(rejected, 'forbidden headers');
    final socket = await WebSocketBrowserConnection.connect(
        base.replace(scheme: 'ws', path: '/ws'));
    final message = socket.messages.first;
    socket.send('browser socket');
    check(await message == 'browser socket', 'WebSocket echo');
    await socket.close();
    testBody.setAttribute('data-result', 'PASS');
  } catch (error, stack) {
    testBody.setAttribute('data-result', 'FAIL: $error $stack');
  } finally {
    client.dispose();
    await transport.close();
  }
}
