import 'package:flutter_client_factory/authentication.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:test/test.dart';

import '../fixtures/counting_token_provider.dart';

void main() {
  test('simultaneous 401s refresh once and isolate other origins', () async {
    final provider = CountingTokenProvider();
    final coordinator = TokenRefreshCoordinator(provider);
    final auth = AuthenticationInterceptor(
        coordinator: coordinator, allowedOrigins: {'https://example.invalid'});
    final request = HttpRequest(uri: Uri.parse('https://example.invalid/'));
    Future<HttpResponse> next(
            HttpRequest request, CancellationToken token) async =>
        HttpResponse.bytes(
            statusCode: request.headers['authorization'].contains('Bearer new')
                ? 200
                : 401);
    final responses = await Future.wait(List.generate(
        8, (_) => auth.intercept(request, CancellationToken(), next)));
    expect(provider.refreshes, 1);
    expect(responses.every((response) => response.isSuccessful), isTrue);
    for (final response in responses) {
      await response.dispose();
    }
    final external = await auth.intercept(
        request.copyWith(uri: Uri.parse('https://other.invalid/')),
        CancellationToken(), (request, token) async {
      expect(request.headers.contains('authorization'), isFalse);
      return HttpResponse.bytes(statusCode: 200);
    });
    await external.dispose();
    coordinator.dispose();
  });
}
