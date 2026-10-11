import 'dart:io' as io;
import 'package:flutter_client/flutter_client.dart';
import 'package:flutter_client/sse.dart';
import 'package:flutter_client/websocket_io.dart';

Future<void> main() async {
  final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    if (request.uri.path == '/socket') {
      final socket = await io.WebSocketTransformer.upgrade(request);
      socket.listen(socket.add, onDone: socket.close);
      return;
    }
    request.response.headers.set('content-type', 'text/event-stream');
    request.response.write('id: 1\ndata: Hello from SSE\n\n');
    await request.response.close();
  });
  final transport = createPlatformTransport();
  final client = HttpClientService(transport: transport);
  final origin = Uri.parse('http://127.0.0.1:${server.port}');
  try {
    final events = ServerSentEventsClient(client, maxReconnects: 0);
    await for (final event in events.connect(origin.resolve('/events'))) {
      io.stdout.writeln(event.data);
    }
    final socket = await IoWebSocketConnection.connect(
        origin.replace(scheme: 'ws', path: '/socket'));
    try {
      final reply = socket.messages.first;
      socket.send('Hello from WebSocket');
      io.stdout.writeln(await reply);
    } finally {
      await socket.close();
    }
  } finally {
    client.dispose();
    await transport.close();
    await server.close(force: true);
  }
}
