import '../bodies/byte_request_body.dart';
import '../bodies/request_body.dart';
import '../bodies/text_request_body.dart';

/// One named multipart field with an optional file name and content headers.
class MultipartPart {
  MultipartPart({required this.name, required this.body, this.filename}) {
    for (final value in [name, filename, body.contentType]) {
      if (value != null && RegExp(r'[\r\n\x00]').hasMatch(value)) {
        throw ArgumentError(
            'Multipart metadata cannot contain control characters.');
      }
    }
  }

  /// A replayable UTF-8 field.
  factory MultipartPart.text({required String name, required String value}) =>
      MultipartPart(name: name, body: TextRequestBody(value));

  /// A replayable defensive byte snapshot with optional filename.
  factory MultipartPart.bytes(
          {required String name,
          required List<int> bytes,
          String? filename,
          String contentType = 'application/octet-stream'}) =>
      MultipartPart(
          name: name,
          filename: filename,
          body: ByteRequestBody(bytes, contentType: contentType));

  final String name;
  final String? filename;
  final RequestBody body;
}
