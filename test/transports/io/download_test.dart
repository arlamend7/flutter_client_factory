import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_client/downloads.dart';
import 'package:flutter_client/flutter_client.dart';
import 'package:flutter_client/io.dart';
import 'package:test/test.dart';

void main() {
  test('download resumes only a matching partial representation', () async {
    final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      expect(request.headers.value('range'), 'bytes=3-');
      expect(request.headers.value('if-range'), '"v1"');
      request.response.statusCode = 206;
      request.response.headers.set('etag', '"v1"');
      request.response.headers.set('content-range', 'bytes 3-5/6');
      request.response.write('def');
      await request.response.close();
    });
    final directory =
        await io.Directory.systemTemp.createTemp('client-download-');
    final destination = io.File('${directory.path}/output');
    final uri = Uri.parse('http://127.0.0.1:${server.port}/file');
    await io.File('${destination.path}.part').writeAsString('abc');
    await io.File('${destination.path}.part.json')
        .writeAsString(jsonEncode({'url': uri.toString(), 'etag': '"v1"'}));
    final transport = IoHttpTransport();
    try {
      await ResumableDownloader(HttpClientService(transport: transport))
          .download(uri, destination);
      expect(await destination.readAsString(), 'abcdef');
      expect(await io.File('${destination.path}.part').exists(), isFalse);
    } finally {
      await transport.close();
      await server.close(force: true);
      await directory.delete(recursive: true);
    }
  });
}
