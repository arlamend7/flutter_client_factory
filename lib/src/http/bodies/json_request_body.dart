import 'dart:convert';
import '../defaults/http_defaults.dart';
import 'byte_request_body.dart';

/// Serializes once so caller mutations cannot change a later retry.
class JsonRequestBody extends ByteRequestBody {
  JsonRequestBody(Object? value)
      : super(
          utf8.encode(jsonEncode(value)),
          contentType: HttpDefaults.jsonContentType,
        );
}
