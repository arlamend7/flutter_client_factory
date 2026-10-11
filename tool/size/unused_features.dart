// ignore_for_file: unused_import
import 'package:flutter_client_factory/authentication.dart';
import 'package:flutter_client_factory/caching.dart';
import 'package:flutter_client_factory/diagnostics.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/resilience.dart';
import 'package:flutter_client_factory/resources.dart';
import 'package:flutter_client_factory/sse.dart';
import 'package:flutter_client_factory/websocket.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) throw ArgumentError('Provide an HTTP endpoint.');
  final transport = createPlatformTransport();
  final client = HttpClientService(transport: transport);
  try {
    final response =
        await client.send(HttpRequest(uri: Uri.parse(arguments.first)));
    // ignore: avoid_print
    print(await const ResponseBodyReader().readText(response));
  } finally {
    client.dispose();
    await transport.close();
  }
}
