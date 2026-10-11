import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/testing.dart';

Future<void> main() async {
  await _streamMemory();
  for (final count in [0, 5]) {
    await _middleware(count);
  }
}

Future<void> _streamMemory() async {
  final chunk = Uint8List(64 * 1024);
  Stream<List<int>> source() async* {
    for (var i = 0; i < 1024; i++) {
      yield chunk;
    }
  }

  final initial = ProcessInfo.currentRss;
  var peak = initial;
  var bytes = 0;
  final response = HttpResponse(statusCode: 200, body: source());
  await for (final chunk in response.body) {
    bytes += chunk.length;
    if (bytes % (1024 * 1024) == 0) {
      final current = ProcessInfo.currentRss;
      if (current > peak) peak = current;
    }
  }
  await response.dispose();
  stdout.writeln(
      'Streamed $bytes bytes; sampled RSS growth ${peak - initial} bytes.');
}

Future<void> _middleware(int count) async {
  final transport = FakeHttpTransport(
      (request, token) async => HttpResponse.bytes(statusCode: 204));
  final client = HttpClientService(
      transport: transport,
      options: HttpClientOptions(
        interceptors: List.generate(
            count, (_) => (request, token, next) => next(request, token)),
      ));
  final request = HttpRequest(uri: Uri.parse('https://benchmark.invalid/'));
  const iterations = 5000;
  final watch = Stopwatch();
  try {
    for (var i = 0; i < 100; i++) {
      await (await client.send(request)).dispose();
    }
    watch.start();
    for (var i = 0; i < iterations; i++) {
      await (await client.send(request)).dispose();
    }
    watch.stop();
    stdout.writeln(
        '$count pass-through interceptors: ${watch.elapsedMicroseconds / iterations} us/op ($iterations iterations).');
  } finally {
    client.dispose();
    await transport.close();
  }
}
