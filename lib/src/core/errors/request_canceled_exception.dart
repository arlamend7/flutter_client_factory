/// A request canceled by its caller, distinct from a timeout.
class RequestCanceledException implements Exception {
  const RequestCanceledException([this.reason]);

  final String? reason;

  @override
  String toString() {
    if (reason == null) return 'RequestCanceledException';
    return 'RequestCanceledException: $reason';
  }
}
