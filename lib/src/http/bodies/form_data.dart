import '../models/multipart_part.dart';
import 'multipart_request_body.dart';

/// Multipart form fields and file/stream parts using the existing streaming encoder.
/// For repeated field names, supply MultipartPart.text entries in [parts].
class FormData extends MultipartRequestBody {
  FormData(
      {Map<String, String> fields = const {},
      Iterable<MultipartPart> files = const [],
      Iterable<MultipartPart> parts = const []})
      : super([
          ...fields.entries.map((entry) =>
              MultipartPart.text(name: entry.key, value: entry.value)),
          ...files,
          ...parts,
        ]);
}
