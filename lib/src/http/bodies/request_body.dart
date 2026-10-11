/// An encoded body. Retrying middleware must check [isReplayable].
abstract class RequestBody {
  String? get contentType;
  int? get contentLength;
  bool get isReplayable;

  /// Opens a new stream. Replayable implementations allow repeated calls.
  Stream<List<int>> openRead();
}
