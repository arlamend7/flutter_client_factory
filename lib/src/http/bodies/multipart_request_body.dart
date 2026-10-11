import 'dart:convert';
import 'dart:math';
import '../models/multipart_part.dart';
import 'request_body.dart';

/// Streaming multipart/form-data with a generated boundary.
/// Replayability and known content length depend on every part.
class MultipartRequestBody implements RequestBody {
  MultipartRequestBody(Iterable<MultipartPart> parts)
      : parts = List.unmodifiable(parts),
        boundary =
            'dart-client-${List.generate(24, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  final List<MultipartPart> parts;
  final String boundary;
  String _quote(String value) =>
      value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  List<int> _prefix(MultipartPart part) => utf8.encode('--$boundary\r\n'
      'Content-Disposition: form-data; name="${_quote(part.name)}"'
      '${part.filename == null ? '' : '; filename="${_quote(part.filename!)}"'}\r\n'
      '${part.body.contentType == null ? '' : 'Content-Type: ${part.body.contentType}\r\n'}\r\n');
  @override
  String get contentType => 'multipart/form-data; boundary=$boundary';
  @override
  bool get isReplayable => parts.every((part) => part.body.isReplayable);
  @override
  int? get contentLength {
    var total = utf8.encode('--$boundary--\r\n').length;
    for (final part in parts) {
      final length = part.body.contentLength;
      if (length == null) return null;
      total += _prefix(part).length + length + 2;
    }
    return total;
  }

  @override
  Stream<List<int>> openRead() async* {
    for (final part in parts) {
      yield _prefix(part);
      yield* part.body.openRead();
      yield const [13, 10];
    }
    yield utf8.encode('--$boundary--\r\n');
  }
}
