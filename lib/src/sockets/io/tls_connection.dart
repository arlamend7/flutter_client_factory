import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../core/cancellation/cancellation_token.dart';

/// Native TLS byte stream using the caller-selected trust context.
class TlsConnection {
  TlsConnection._(this._socket);
  final SecureSocket _socket;
  static Future<TlsConnection> connect(String host, int port,
      {SecurityContext? context,
      CancellationToken? cancellationToken,
      Duration timeout = const Duration(seconds: 15),
      List<String>? supportedProtocols}) async {
    final token = cancellationToken ?? CancellationToken();
    token.throwIfCanceled();
    final pending = SecureSocket.connect(host, port,
        context: context,
        timeout: timeout,
        supportedProtocols: supportedProtocols);
    unawaited(pending.then<void>((socket) {
      if (token.isCanceled) socket.destroy();
    }, onError: (Object e, StackTrace s) {}));
    return TlsConnection._(await token.race(pending));
  }

  String? get selectedProtocol => _socket.selectedProtocol;
  X509Certificate? get peerCertificate => _socket.peerCertificate;
  Stream<Uint8List> get bytes => _socket;
  Future<void> send(List<int> bytes) async {
    _socket.add(bytes);
    await _socket.flush();
  }

  Future<void> close() async {
    _socket.destroy();
  }
}
