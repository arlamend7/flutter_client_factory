import 'dart:convert';
import '../defaults/http_defaults.dart';
import 'byte_request_body.dart';

class TextRequestBody extends ByteRequestBody {
  TextRequestBody(String text)
      : super(utf8.encode(text), contentType: HttpDefaults.textContentType);
}
