class NetworkException implements Exception {
  const NetworkException(this.uri, this.cause, this.stackTrace);
  final Uri uri;
  final Object cause;
  final StackTrace stackTrace;
  @override
  String toString() => 'NetworkException: ${uri.origin}${uri.path}: $cause';
}
