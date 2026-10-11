import 'package:flutter_client/resources.dart';
import 'package:flutter_client_widgets/flutter_client_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
