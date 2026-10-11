import 'package:flutter_client/flutter_client.dart';
import 'package:test/test.dart';

void main() {
  test(
      'copies input and preserves multiple values with case-insensitive lookup',
      () {
    final values = <String>['one', 'two'];
    final headers = HttpHeaders(<String, List<String>>{'X-Tag': values});
    values.add('three');

    expect(headers['x-TAG'], <String>['one', 'two']);
    expect(() => headers['x-tag'].add('four'), throwsUnsupportedError);
  });

  test('request headers override defaults without case-sensitive duplicates',
      () {
    final defaults = HttpHeaders(<String, List<String>>{
      'Accept': <String>['application/json'],
      'X-Tag': <String>['default'],
    });
    final overrides = HttpHeaders(<String, List<String>>{
      'ACCEPT': <String>['text/plain'],
    });

    final merged = defaults.merge(overrides);

    expect(merged['accept'], <String>['text/plain']);
    expect(merged['x-tag'], <String>['default']);
    expect(defaults['accept'], <String>['application/json']);
  });
}
