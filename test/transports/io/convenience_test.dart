import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_client_factory/downloads.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/io.dart';
import 'package:flutter_client_factory/sse.dart';
import 'package:test/test.dart';

void main() {
  test(
      'native shortcuts upload files, download, read SSE, and abort stalled reads',
      () async {
    final directory =
        await io.Directory.systemTemp.createTemp('client-convenience-');
    final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    final factory = DefaultHttpClientFactory();
    addTearDown(() async {
      await factory.close();
      await server.close(force: true);
      await directory.delete(recursive: true);
    });
    server.listen((request) async {
      if (request.uri.path == '/stall') {
        request.response.write('start');
        await request.response.flush();
        return;
      }
      if (request.uri.path == '/events') {
        request.response.headers.contentType =
            io.ContentType('text', 'event-stream');
        request.response.write('data: hello\n\n');
      } else if (request.uri.path == '/upload') {
        final text = await utf8.decoder.bind(request).join();
        expect(text, contains('file content'));
        expect(text, contains('filename="upload.txt"'));
        request.response.write('uploaded');
      } else {
        request.response.write('downloaded');
      }
      await request.response.close();
    });
    final origin = 'http://127.0.0.1:${server.port}/';
    factory.registerClient('api', baseUrl: origin);
    final client = factory.create('api');
    final file = await io.File('${directory.path}/upload.txt')
        .writeAsString('file content');
    final part =
        await file.asMultipartPart(name: 'file', contentType: 'text/plain');
    expect(part.body.isReplayable, isFalse);
    expect(
        await (await client.postAsync('upload', body: FormData(files: [part])))
            .readText(),
        'uploaded');
    final downloaded = await client.downloadFile(
        '${origin}file', io.File('${directory.path}/download'));
    expect(await downloaded.readAsString(), 'downloaded');
    final events =
        await client.serverSentEvents('events', maxReconnects: 0).toList();
    expect(events.single.data, 'hello');
    await expectLater(() async {
      final response = await client.getAsync('stall',
          timeout: const Duration(milliseconds: 150));
      await response.readText();
    }, throwsA(isA<RequestTimeoutException>()));
    expect(await (await client.getAsync('healthy')).readText(), 'downloaded');
  });
}
