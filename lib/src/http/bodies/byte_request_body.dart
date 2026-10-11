import 'dart:typed_data';
import '../defaults/http_defaults.dart';
import 'request_body.dart';

/// A defensive copy of bytes that can be sent more than once.
class ByteRequestBody implements RequestBody {
  ByteRequestBody(
    List<int> bytes, {
    this.contentType = HttpDefaults.binaryContentType,
  }) : _bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  final List<int> _bytes;

  @override
  final String? contentType;

  @override
  int get contentLength => _bytes.length;

  @override
  bool get isReplayable => true;

  @override
  Stream<List<int>> openRead() => Stream<List<int>>.value(_bytes);
}
