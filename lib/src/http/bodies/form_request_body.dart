import 'dart:convert';
import 'byte_request_body.dart';

/// Replayable UTF-8 application/x-www-form-urlencoded fields.
class FormRequestBody extends ByteRequestBody {
  FormRequestBody(Map<String, List<String>> fields)
      : super(
            utf8.encode(fields.entries
                .expand((entry) => entry.value.map((value) =>
                    '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value)}'))
                .join('&')),
            contentType: 'application/x-www-form-urlencoded; charset=utf-8');
}
