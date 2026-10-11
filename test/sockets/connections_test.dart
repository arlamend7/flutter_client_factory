import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_client_factory/sockets.dart';
import 'package:flutter_client_factory/websocket_io.dart';
import 'package:test/test.dart';

void main() {
  test('TCP sends and receives bytes', () async {
    final server =
        await io.ServerSocket.bind(io.InternetAddress.loopbackIPv4, 0);
    server.listen((socket) {
      socket.listen(socket.add, onDone: socket.destroy);
    });
    final client = await TcpConnection.connect('127.0.0.1', server.port);
    try {
      final received = client.bytes.first;
      await client.send(utf8.encode('tcp'));
      expect(utf8.decode(await received), 'tcp');
    } finally {
      await client.close();
      await server.close();
    }
  });
  test('UDP preserves datagram boundaries', () async {
    final first = await UdpConnection.bind(io.InternetAddress.loopbackIPv4, 0);
    final second = await UdpConnection.bind(io.InternetAddress.loopbackIPv4, 0);
    try {
      final received = second.datagrams.first;
      first.send([1, 2, 3], io.InternetAddress.loopbackIPv4, second.port);
      expect((await received).data, [1, 2, 3]);
    } finally {
      first.close();
      second.close();
    }
  });
  test('native WebSocket sends and receives text', () async {
    final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final socket = await io.WebSocketTransformer.upgrade(request);
      socket.listen(socket.add, onDone: socket.close);
    });
    final client = await IoWebSocketConnection.connect(
        Uri.parse('ws://127.0.0.1:${server.port}/'));
    try {
      final received = client.messages.first;
      client.send('socket');
      expect(await received, 'socket');
    } finally {
      await client.close();
      await server.close(force: true);
    }
  });
}
