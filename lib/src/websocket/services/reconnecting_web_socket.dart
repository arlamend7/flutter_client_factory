import 'dart:async';
import '../../core/cancellation/cancellation_token.dart';
import '../contracts/web_socket_connection.dart';
import '../models/web_socket_options.dart';

/// No implicit replay of sent messages. Subscribe before calling [start].
class ReconnectingWebSocket {
  ReconnectingWebSocket(this.connect,
      {this.options = const WebSocketOptions()}) {
    if (options.maxReconnects < 0 ||
        options.reconnectDelay < Duration.zero ||
        options.heartbeatTimeout <= Duration.zero ||
        (options.heartbeatInterval != null &&
            options.heartbeatInterval! <= Duration.zero)) {
      throw ArgumentError('Invalid WebSocket reconnect or heartbeat budget.');
    }
  }

  final Future<WebSocketConnection> Function(CancellationToken token) connect;
  final WebSocketOptions options;
  final StreamController<Object> _messages =
      StreamController<Object>.broadcast();
  final CancellationToken _lifetime = CancellationToken();
  WebSocketConnection? _connection;
  Future<void>? _running;
  Future<void>? _disposing;

  Stream<Object> get messages => _messages.stream;

  /// Runs until reconnection is exhausted or disposal ends the loop.
  Future<void> start() {
    if (_lifetime.isCanceled) throw StateError('WebSocket service disposed.');
    return _running ??= _run();
  }

  void send(Object message) {
    final connection = _connection;
    if (connection == null) throw StateError('WebSocket is not connected.');
    connection.send(message);
  }

  void _report(Object error, StackTrace stack) {
    if (_lifetime.isCanceled || _messages.isClosed) return;
    _messages.addError(error, stack);
  }

  Future<void> _close(WebSocketConnection socket, [String? reason]) async {
    try {
      await socket.close(1000, reason);
    } catch (error, stack) {
      _report(error, stack);
    }
  }

  Future<void> _run() async {
    try {
      for (var attempt = 0; !_lifetime.isCanceled; attempt++) {
        Timer? heartbeat;
        WebSocketConnection? socket;
        Future<void>? closing;
        void Function() remove = () {};
        void close(String reason) {
          heartbeat?.cancel();
          final current = socket;
          if (current == null || closing != null) return;
          closing = _close(current, reason);
        }

        try {
          final connected = await connect(_lifetime);
          socket = connected;
          if (_lifetime.isCanceled) break;
          _connection = connected;
          var lastPong = DateTime.now();
          final interval = options.heartbeatInterval;
          if (interval != null) {
            heartbeat = Timer.periodic(interval, (_) {
              if (DateTime.now().difference(lastPong) >
                  options.heartbeatTimeout) {
                close('Heartbeat timeout');
                return;
              }
              try {
                connected.send(options.ping);
              } catch (error, stack) {
                _report(error, stack);
                close('Heartbeat send failed');
              }
            });
          }
          remove = _lifetime.onCancel(() => close('Disposed'));
          await for (final message in connected.messages) {
            if (message == options.pong) {
              lastPong = DateTime.now();
              continue;
            }
            _messages.add(message);
          }
        } catch (error, stack) {
          _report(error, stack);
        } finally {
          remove();
          heartbeat?.cancel();
          _connection = null;
          final current = socket;
          if (current != null) await (closing ?? _close(current));
        }
        if (_lifetime.isCanceled || attempt >= options.maxReconnects) break;
        try {
          await _lifetime.wait(options.reconnectDelay);
        } catch (_) {
          if (!_lifetime.isCanceled) rethrow;
        }
      }
    } finally {
      await _messages.close();
    }
  }

  /// Cancels the loop and awaits owned connection cleanup, once.
  Future<void> dispose() => _disposing ??= Future<void>.sync(() async {
        _lifetime.cancel();
        final running = _running;
        if (running != null) {
          await running;
          return;
        }
        await _messages.close();
      });
}
