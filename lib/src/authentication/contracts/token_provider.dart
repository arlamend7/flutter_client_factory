import '../../core/cancellation/cancellation_token.dart';

/// Scope providers to one user/session. Refresh must honor cancellation.
abstract class TokenProvider {
  Future<String?> getToken();
  Future<String?> refreshToken(CancellationToken token);
}
