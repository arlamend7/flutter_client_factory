import 'dart:async';

import 'package:flutter_client/resources.dart';
import 'package:test/test.dart';

void main() {
  test('a late superseded read cannot overwrite the newer result', () async {
    final first = Completer<int>();
    var calls = 0;
    final resource = HttpResource<int>((token) {
      calls++;
      return calls == 1 ? first.future : Future.value(2);
    });
    final pending = resource.refresh();
    await resource.refresh();
    first.complete(1);
    await pending;
    expect(resource.state.data, 2);
    expect(resource.state.isLoading, isFalse);
    await resource.dispose();
  });
}
