import 'dart:async';

import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/resources.dart';
import 'package:flutter_client_factory_widgets/flutter_client_factory_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'loader constructor creates an owned cancellable resource without eager work',
      () async {
    var calls = 0;
    late CancellationToken active;
    final notifier = HttpResourceNotifier<int>.fromLoader((token) async {
      calls++;
      active = token;
      return token.race(Completer<int>().future);
    });
    expect(calls, 0);
    final pending = notifier.refresh();
    expect(calls, 1);
    notifier.dispose();
    expect(active.isCanceled, isTrue);
    await pending;
    await expectLater(notifier.refresh(), throwsStateError);
  });

  test('notifier publishes resource reads and owns disposal', () async {
    final resource = HttpResource<int>((token) async => 42);
    final notifier = HttpResourceNotifier(resource);
    await notifier.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(notifier.value.data, 42);
    expect(notifier.value.isLoading, isFalse);
    notifier.dispose();
    await expectLater(resource.refresh(), throwsStateError);
  });
}
