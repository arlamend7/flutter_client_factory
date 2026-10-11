import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../core/cancellation/cancellation_token.dart';

/// Native TCP byte stream with explicit connection and shutdown ownership.
class TcpConnection {
  TcpConnection(this.socket);
  final Socket socket;
  static Future<TcpConnection> connect(String host, int port,
      {CancellationToken? cancellationToken,
      Duration timeout = const Duration(seconds: 15)}) async {
    final token = cancellationToken ?? CancellationToken();
    token.throwIfCanceled();
    final task = await Socket.startConnect(host, port);
    final remove = token.onCancel(task.cancel);
    try {
      final pending = task.socket.timeout(timeout, onTimeout: () {
        task.cancel();
        throw TimeoutException('TCP connection timed out', timeout);
      });
      return TcpConnection(await token.race(pending));
    } finally {
      remove();
    }
  }

  Stream<Uint8List> get bytes => socket;
  Future<void> send(List<int> bytes) async {
    socket.add(bytes);
    await socket.flush();
  }

  Future<void> close() async {
    socket.destroy();
  }
}
