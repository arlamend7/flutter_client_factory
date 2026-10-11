import 'dart:async';
import '../../core/cancellation/cancellation_token.dart';
import '../contracts/token_provider.dart';

/// Coalesces concurrent refreshes for one session.
/// Canceling a caller stops its wait, while other callers retain the shared refresh.
class TokenRefreshCoordinator {
  TokenRefreshCoordinator(this.provider);
  final TokenProvider provider;
  final CancellationToken _lifetime = CancellationToken();
  Future<String?>? _refreshing;
  Future<String?> refresh(String? rejected, CancellationToken caller) async {
    _lifetime.throwIfCanceled();
    final current = await caller.race(provider.getToken());
    if (current != rejected) return current;
    final task = _refreshing ??=
        Future<String?>.sync(() => provider.refreshToken(_lifetime));
    try {
      return await caller.race(task);
    } finally {
      // Clear only when the shared work completes, not when one waiter cancels.
      unawaited(task.then<void>((_) {
        if (identical(_refreshing, task)) _refreshing = null;
      }, onError: (Object e, StackTrace s) {
        if (identical(_refreshing, task)) _refreshing = null;
      }));
    }
  }

  void dispose() => _lifetime.cancel('Authentication session disposed.');
}
