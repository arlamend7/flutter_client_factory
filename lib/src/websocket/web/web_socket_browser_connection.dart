import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import '../../core/cancellation/cancellation_token.dart';
import '../contracts/web_socket_connection.dart';
import 'interop/browser_message_event.dart';
import 'interop/browser_web_socket.dart';

/// Browser WebSocket adapter for text and bytes without custom request headers.
class WebSocketBrowserConnection implements WebSocketConnection {
  WebSocketBrowserConnection._(this._socket);
  final BrowserWebSocket _socket;
  // Closed by the browser onclose handler.
  // ignore: close_sinks
  final StreamController<Object> _messages = StreamController();
  final Completer<void> _closed = Completer<void>();
  static Future<WebSocketBrowserConnection> connect(Uri uri,
      {List<String> protocols = const [],
      CancellationToken? cancellationToken}) async {
    final token = cancellationToken ?? CancellationToken();
    token.throwIfCanceled();
    final socket = BrowserWebSocket(
        uri.toString(), protocols.map((value) => value.toJS).toList().toJS);
    final connection = WebSocketBrowserConnection._(socket);
    final opened = Completer<void>();
    socket.binaryType = 'arraybuffer';
    socket.onopen = ((JSAny? event) {
      if (!opened.isCompleted) opened.complete();
    }).toJS;
    socket.onmessage = ((BrowserMessageEvent event) {
      final data = event.data;
      if (data.typeofEquals('string')) {
        connection._messages.add((data as JSString).toDart);
      } else {
        connection._messages.add((data as JSArrayBuffer).toDart.asUint8List());
      }
    }).toJS;
    socket.onerror = ((JSAny? event) {
      final error = StateError('WebSocket connection failed.');
      if (!opened.isCompleted) {
        opened.completeError(error);
      } else {
        connection._messages.addError(error);
      }
    }).toJS;
    socket.onclose = ((JSAny? event) {
      if (!opened.isCompleted) {
        opened.completeError(StateError('WebSocket closed before opening.'));
      }
      unawaited(connection._messages.close());
      if (!connection._closed.isCompleted) connection._closed.complete();
    }).toJS;
    final remove = token.onCancel(() => socket.close());
    try {
      await token.race(opened.future);
      return connection;
    } catch (_) {
      socket.close();
      rethrow;
    } finally {
      remove();
    }
  }

  @override
  Stream<Object> get messages => _messages.stream;
  @override
  void send(Object message) {
    if (_socket.readyState != 1) throw StateError('WebSocket is not open.');
    if (message is String) {
      _socket.send(message.toJS);
      return;
    }
    if (message is List<int>) {
      _socket.send(Uint8List.fromList(message).toJS);
      return;
    }
    throw ArgumentError('Expected text or bytes.');
  }

  @override
  Future<void> close([int? code, String? reason]) {
    if (!_closed.isCompleted) _socket.close(code ?? 1000, reason ?? '');
    return _closed.future;
  }
}
