import 'dart:async';
import 'package:flutter_client/websocket.dart';

class MemoryWebSocketConnection implements WebSocketConnection {
  final StreamController<Object> incoming = StreamController();
  final List<Object> sent = [];
  bool failSend = false;
  bool closed = false;
  @override
  Stream<Object> get messages => incoming.stream;
  @override
  void send(Object message) {
    if (failSend) throw StateError('send failed');
    sent.add(message);
  }

  @override
  Future<void> close([int? code, String? reason]) async {
    if (closed) return;
    closed = true;
    await incoming.close();
  }
}
