import 'dart:io' as io;

import 'package:flutter_client_factory/cookies.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/io.dart';
import 'package:test/test.dart';

void main() {
  test('cross-origin redirects remove credentials', () async {
    final target = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    target.listen((request) async {
      expect(request.headers.value('authorization'), isNull);
      expect(request.headers.value('cookie'), isNull);
      request.response.write('safe');
      await request.response.close();
    });
    final source = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    source.listen((request) async {
      request.response.statusCode = 302;
      request.response.headers
          .set('location', 'http://127.0.0.1:${target.port}/target');
      await request.response.close();
    });
    final transport = IoHttpTransport();
    try {
      final response = await transport.send(
          HttpRequest(
              uri: Uri.parse('http://127.0.0.1:${source.port}/'),
              headers: HttpHeaders({
                'authorization': ['secret'],
                'cookie': ['user=secret']
              })),
          CancellationToken());
      expect(response.uri!.port, target.port);
      expect(await const ResponseBodyReader().readText(response), 'safe');
    } finally {
      await transport.close();
      await source.close(force: true);
      await target.close(force: true);
    }
  });
  test('custom TLS trust validates the server certificate', () async {
    final serverContext = io.SecurityContext()
      ..useCertificateChain('test/fixtures/tls/server.crt')
      ..usePrivateKey('test/fixtures/tls/server.key');
    final trust = io.SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificates('test/fixtures/tls/ca.crt');
    final server = await io.HttpServer.bindSecure(
        io.InternetAddress.loopbackIPv4, 0, serverContext);
    server.listen((request) async {
      request.response.write('secure');
      await request.response.close();
    });
    final transport =
        IoHttpTransport(options: IoTransportOptions(securityContext: trust));
    try {
      final response = await transport.send(
          HttpRequest(uri: Uri.parse('https://127.0.0.1:${server.port}/')),
          CancellationToken());
      expect(await const ResponseBodyReader().readText(response), 'secure');
    } finally {
      await transport.close();
      await server.close(force: true);
    }
  });
  test('cookie jar enforces host, path, secure and expiry boundaries', () {
    var now = DateTime.utc(2026);
    final jar = CookieJar(clock: () => now);
    jar.store(Uri.parse('https://api.example.invalid/private/x'), [
      'session=one; Path=/private; Secure; Max-Age=1',
      'bad=two; Domain=example.invalid'
    ]);
    expect(jar.header(Uri.parse('https://api.example.invalid/private/y')),
        'session=one');
    expect(jar.header(Uri.parse('http://api.example.invalid/private/y')), '');
    expect(
        jar.header(Uri.parse('https://api.example.invalid/private-other')), '');
    now = now.add(const Duration(seconds: 2));
    expect(jar.header(Uri.parse('https://api.example.invalid/private/y')), '');
  });
}
