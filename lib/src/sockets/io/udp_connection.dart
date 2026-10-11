import 'dart:io';

/// Native UDP endpoint that preserves incoming datagram boundaries.
class UdpConnection {
  UdpConnection._(this._socket);
  final RawDatagramSocket _socket;
  static Future<UdpConnection> bind(InternetAddress address, int port) async =>
      UdpConnection._(await RawDatagramSocket.bind(address, port));
  int get port => _socket.port;
  Stream<Datagram> get datagrams async* {
    await for (final event in _socket) {
      if (event != RawSocketEvent.read) continue;
      Datagram? packet;
      while ((packet = _socket.receive()) != null) {
        yield packet!;
      }
    }
  }

  int send(List<int> bytes, InternetAddress address, int port) =>
      _socket.send(bytes, address, port);
  void close() => _socket.close();
}
