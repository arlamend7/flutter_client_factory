import '../bodies/request_body.dart';

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
  final String name;
  final String? filename;
  final RequestBody body;
}
