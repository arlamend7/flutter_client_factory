import 'dart:async';
import 'package:flutter_client_factory/websocket.dart';
import 'package:test/test.dart';
import '../fixtures/memory_web_socket_connection.dart';

void main() {
  test('reconnect loop obeys its total budget and closes every connection',
      () async {
    final sockets = <MemoryWebSocketConnection>[];
    final service = ReconnectingWebSocket((token) async {
      final socket = MemoryWebSocketConnection();
      sockets.add(socket);
      scheduleMicrotask(() => unawaited(socket.close()));
      return socket;
    },
        options: const WebSocketOptions(
            maxReconnects: 2, reconnectDelay: Duration.zero));
    final subscription = service.messages.listen((_) {});
    await service.start();
    expect(sockets.length, 3);
    expect(sockets.every((socket) => socket.closed), isTrue);
    await service.dispose();
    await subscription.cancel();
  });
  test('heartbeat send errors are reported and end the connection safely',
      () async {
    final socket = MemoryWebSocketConnection()..failSend = true;
    final service = ReconnectingWebSocket((token) async => socket,
        options: const WebSocketOptions(
            maxReconnects: 0, heartbeatInterval: Duration(milliseconds: 1)));
    final errors = <Object>[];
    final subscription = service.messages.listen((_) {}, onError: errors.add);
    await service.start();
    expect(errors.single, isA<StateError>());
    expect(socket.closed, isTrue);
    await service.dispose();
    await subscription.cancel();
  });
}
