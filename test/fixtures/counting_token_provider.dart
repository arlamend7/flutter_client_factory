import 'package:flutter_client/authentication.dart';
import 'package:flutter_client/flutter_client.dart';

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
