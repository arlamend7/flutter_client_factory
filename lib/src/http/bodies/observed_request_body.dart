import 'request_body.dart';

class ObservedRequestBody implements RequestBody {
  ObservedRequestBody(this.source, this.onProgress);
  final RequestBody source;
  final void Function(int bytes) onProgress;
  @override
  String? get contentType => source.contentType;
  @override
  int? get contentLength => source.contentLength;
  @override
  bool get isReplayable => source.isReplayable;
  @override
  Stream<List<int>> openRead() async* {
    var transferred = 0;
    await for (final chunk in source.openRead()) {
      transferred += chunk.length;
      onProgress(transferred);
      yield chunk;
    }
  }
}
