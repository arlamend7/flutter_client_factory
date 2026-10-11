import 'package:flutter_client_factory/flutter_client_factory.dart';

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
