/// Finite retry budget with jitter bounds and explicit permission for writes.
class RetryOptions {
  RetryOptions(
      {this.maxAttempts = 3,
      this.baseDelay = const Duration(milliseconds: 200),
      this.maxDelay = const Duration(seconds: 30),
      this.retryWrites = false,
      Set<int> statuses = const {408, 429, 500, 502, 503, 504}})
      : statuses = Set.unmodifiable(statuses) {
    if (maxAttempts < 1 || baseDelay < Duration.zero || maxDelay < baseDelay) {
      throw ArgumentError('Invalid retry budget.');
    }
  }

  /// Total attempts, including the original send.
  final int maxAttempts;
  final Duration baseDelay;

  /// Maximum backoff. Larger Retry-After values return the response without retry.
  final Duration maxDelay;

  /// Explicitly permits replayable writes; server idempotency remains caller policy.
  final bool retryWrites;
  final Set<int> statuses;
}
