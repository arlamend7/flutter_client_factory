import 'package:flutter_client_factory/authentication.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/resilience.dart';
import 'package:flutter_client_factory/testing.dart';
import 'services/demo_token_provider.dart';

Future<void> main() async {
  final controller = HttpTestingController();
  final coordinator = TokenRefreshCoordinator(DemoTokenProvider());
  final client = controller.createClient(
    baseUrl: 'https://example.invalid/',
    timeout: const Duration(seconds: 5),
    interceptors: [
      RetryInterceptor(options: RetryOptions(baseDelay: Duration.zero))
          .intercept,
      AuthenticationInterceptor(
          coordinator: coordinator,
          allowedOrigins: {'https://example.invalid'}).intercept,
    ],
  );
  try {
    final pending = client.getAsync('profile');
    (await controller.waitForOne('https://example.invalid/profile'))
        .flushText('Temporarily unavailable', statusCode: 503);
    (await controller.waitForOne('https://example.invalid/profile'))
        .flushText('Refresh required', statusCode: 401);
    final authorized =
        await controller.waitForOne('https://example.invalid/profile');
    if (authorized.request.headers['authorization'].single !=
        'Bearer demo-new') {
      throw StateError('Expected refreshed demonstration credentials');
    }
    authorized.flushJson({'name': 'Ada'});
    final response = await pending;
    await response.requireSuccess();
    // ignore: avoid_print
    print(await response.readJson(decode: (json) => json));
    controller.verify();
  } finally {
    client.dispose();
    coordinator.dispose();
    await controller.close();
  }
}
