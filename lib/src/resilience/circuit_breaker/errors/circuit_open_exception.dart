/// The shared circuit breaker is open and prevented a transport dispatch.
class CircuitOpenException implements Exception {
  const CircuitOpenException(this.retryAt);
  final DateTime retryAt;
  @override
  String toString() => 'Circuit is open until $retryAt';
}
