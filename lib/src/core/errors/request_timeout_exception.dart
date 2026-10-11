class RequestTimeoutException implements Exception {
  const RequestTimeoutException(this.duration, {this.phase = 'operation'});
  final Duration duration;
  final String phase;
  @override
  String toString() => 'RequestTimeoutException: $phase exceeded $duration';
}
