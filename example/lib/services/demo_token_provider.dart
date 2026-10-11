import 'package:flutter_client_factory/authentication.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';

/// In-memory demo credentials only; production implementations use a secure store.
class DemoTokenProvider implements TokenProvider {
  String _token = 'demo-old';
  @override
  Future<String?> getToken() async => _token;
  @override
  Future<String?> refreshToken(CancellationToken token) async {
    token.throwIfCanceled();
    return _token = 'demo-new';
  }
}
