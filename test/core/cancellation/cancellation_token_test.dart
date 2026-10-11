import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:test/test.dart';

void main() {
  test('cancellation completes its signal once and preserves the first reason',
      () async {
    final token = CancellationToken();
    final completed = expectLater(token.whenCanceled, completes);

    token.cancel('Screen closed');
    token.cancel('Different reason');

    await completed;
    expect(token.reason, 'Screen closed');
    expect(token.throwIfCanceled, throwsA(isA<RequestCanceledException>()));
  });
}
