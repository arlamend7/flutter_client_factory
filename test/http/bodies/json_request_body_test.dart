import 'dart:convert';
import 'package:flutter_client/flutter_client.dart';
import 'package:test/test.dart';

void main() {
  test('JSON snapshots remain stable across caller mutation and repeated sends',
      () async {
    final value = <String, Object?>{'name': 'Ada'};
    final body = JsonRequestBody(value);
    value['name'] = 'Changed';

    final first = await body.openRead().expand((chunk) => chunk).toList();
    final second = await body.openRead().expand((chunk) => chunk).toList();

    expect(jsonDecode(utf8.decode(first)), <String, Object?>{'name': 'Ada'});
    expect(second, first);
    expect(body.contentLength, first.length);
  });
}
