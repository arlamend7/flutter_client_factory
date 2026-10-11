import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/testing.dart';

Future<void> main() async {
  final controller = HttpTestingController();
  final client = controller.createClient(baseUrl: 'https://example.invalid/');
  try {
    final pending = client.getAsync('users');
    final request = await controller.waitForOne('https://example.invalid/users',
        method: HttpMethod.get);
    request.flushJson(['Ada']);
    final response = await pending;
    // ignore: avoid_print
    print(await response.readJson(decode: (json) => json));
    controller.verify();
  } finally {
    client.dispose();
    await controller.close();
  }
}
