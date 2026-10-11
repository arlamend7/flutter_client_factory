import 'package:flutter_client_factory/authentication.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';

class CountingTokenProvider implements TokenProvider {
  String current = 'old';
  int refreshes = 0;
  @override
  Future<String?> getToken() async => current;
  @override
  Future<String?> refreshToken(CancellationToken token) async {
    refreshes++;
    await token.wait(const Duration(milliseconds: 10));
    current = 'new';
    return current;
  }
}
