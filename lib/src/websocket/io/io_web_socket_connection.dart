import 'dart:async';
import 'dart:io' as io;
import '../../core/cancellation/cancellation_token.dart';
import '../contracts/web_socket_connection.dart';

/// Native SDK WebSocket adapter with optional protocol-level ping frames.
class IoWebSocketConnection implements WebSocketConnection {
  IoWebSocketConnection._(this._socket);
  final io.WebSocket _socket;
  static Future<IoWebSocketConnection> connect(Uri uri,
      {CancellationToken? cancellationToken,
      Map<String, String>? headers,
      Iterable<String>? protocols,
      Duration? pingInterval}) async {
    final token = cancellationToken ?? CancellationToken();
    token.throwIfCanceled();
    final pending = io.WebSocket.connect(uri.toString(),
        headers: headers, protocols: protocols);
    unawaited(pending.then<void>((socket) async {
      if (token.isCanceled) await socket.close();
    }, onError: (Object e, StackTrace s) {}));
    // Ownership transfers to the returned connection.
    // ignore: close_sinks
    final socket = await token.race(pending);
    socket.pingInterval = pingInterval;
    return IoWebSocketConnection._(socket);
  }

  @override
  Stream<Object> get messages =>
      _socket.map((dynamic event) => event as Object);
  @override
  void send(Object message) {
    if (message is! String && message is! List<int>) {
      throw ArgumentError('Expected text or bytes.');
    }
    _socket.add(message);
  }

  @override
  Future<void> close([int? code, String? reason]) async {
    await _socket.close(code, reason);
  }
}
