import 'request_body.dart';

/// Caller-supplied upload stream with explicit replayability.
/// The default constructor permits one read; a replay factory must produce equivalent bytes.
class StreamRequestBody implements RequestBody {
  StreamRequestBody(Stream<List<int>> stream,
      {this.contentType, this.contentLength})
      : _open = (() => stream),
        isReplayable = false;
  StreamRequestBody.replayable(Stream<List<int>> Function() open,
      {this.contentType, this.contentLength})
      : _open = open,
        isReplayable = true;
  final Stream<List<int>> Function() _open;
  bool _opened = false;
  @override
  final bool isReplayable;
  @override
  final String? contentType;
  @override
  final int? contentLength;
  @override
  Stream<List<int>> openRead() {
    if (_opened && !isReplayable) {
      throw StateError('This body cannot be replayed.');
    }
    _opened = true;
    return _open();
  }
}
