import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_client/flutter_client.dart';
import 'package:flutter_client/io.dart';
import 'package:test/test.dart';

void main() {
  test('native upload, response streaming and connection reuse', () async {
    final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    final ports = <int>{};
    server.listen((request) async {
      ports.add(request.connectionInfo!.remotePort);
      final text = await utf8.decoder.bind(request).join();
      request.response.write(text.isEmpty ? 'hello' : text);
      await request.response.close();
    });
    final transport = IoHttpTransport();
    final client = HttpClientService(transport: transport);
    addTearDown(() async {
      await transport.close();
      await server.close(force: true);
    });
    final uri = Uri.parse('http://127.0.0.1:${server.port}/');
    final first = await client.send(HttpRequest(
        uri: uri, method: HttpMethod.post, body: TextRequestBody('upload')));
    expect(await const ResponseBodyReader().readText(first), 'upload');
    final second = await client.send(HttpRequest(uri: uri));
    expect(await const ResponseBodyReader().readText(second), 'hello');
    expect(ports.length, 1);
  });
  test('canceling a pending request does not kill another request', () async {
    final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    final started = Completer<void>();
    server.listen((request) async {
      if (request.uri.path == '/slow') {
        started.complete();
        return;
      }
      request.response.write('ok');
      await request.response.close();
    });
    final transport = IoHttpTransport(
        options: const IoTransportOptions(
            shutdownTimeout: Duration(milliseconds: 50)));
    final client = HttpClientService(transport: transport);
    addTearDown(() async {
      await transport.close();
      await server.close(force: true);
    });
    final token = CancellationToken();
    final pending = client.send(
        HttpRequest(uri: Uri.parse('http://127.0.0.1:${server.port}/slow')),
        cancellationToken: token);
    final assertion =
        expectLater(pending, throwsA(isA<RequestCanceledException>()));
    await started.future;
    token.cancel();
    await assertion;
    final response = await client.send(
        HttpRequest(uri: Uri.parse('http://127.0.0.1:${server.port}/fast')));
    expect(await const ResponseBodyReader().readText(response), 'ok');
  });
  test('canceling after headers interrupts a body stalled without chunks',
      () async {
    final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.write('start');
      await request.response.flush();
    });
    final transport = IoHttpTransport(
        options: const IoTransportOptions(
            shutdownTimeout: Duration(milliseconds: 50)));
    addTearDown(() async {
      await transport.close();
      await server.close(force: true);
    });
    final token = CancellationToken();
    final response = await transport.send(
        HttpRequest(uri: Uri.parse('http://127.0.0.1:${server.port}/')), token);
    final assertion = expectLater(const ResponseBodyReader().readText(response),
        throwsA(isA<RequestCanceledException>()));
    token.cancel();
    await assertion;
  });
}
