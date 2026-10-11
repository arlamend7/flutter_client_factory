import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/resilience.dart';
import 'package:test/test.dart';

void main() {
  test('failover strips credentials when switching origins', () async {
    final policy = FailoverInterceptor([Uri.parse('https://backup.invalid')]);
    final request = HttpRequest(
        uri: Uri.parse('https://primary.invalid/path'),
        headers: HttpHeaders({
          'authorization': ['secret']
        }));
    final response = await policy.intercept(request, CancellationToken(),
        (request, token) async {
      if (request.uri.host == 'primary.invalid') {
        return HttpResponse.bytes(statusCode: 503);
      }
      expect(request.uri.path, '/path');
      expect(request.headers.contains('authorization'), isFalse);
      return HttpResponse.bytes(statusCode: 200);
    });
    expect(response.statusCode, 200);
    await response.dispose();
  });
  test('hedging cancels the losing attempt', () async {
    final policy = HedgingInterceptor(delay: const Duration(milliseconds: 5));
    var calls = 0;
    var canceled = false;
    final response = await policy.intercept(
        HttpRequest(uri: Uri.parse('https://example.invalid/')),
        CancellationToken(), (request, token) async {
      calls++;
      if (calls == 1) {
        try {
          await token.wait(const Duration(seconds: 10));
        } catch (_) {
          canceled = true;
          rethrow;
        }
      }
      return HttpResponse.bytes(statusCode: 200);
    });
    await Future<void>.delayed(Duration.zero);
    expect(canceled, isTrue);
    expect(calls, 2);
    await response.dispose();
  });
}
