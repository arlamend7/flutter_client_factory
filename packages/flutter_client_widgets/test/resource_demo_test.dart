import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../example/lib/resource_demo.dart';

void main() {
  testWidgets('example refresh replaces a pending read and disposes cleanly',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResourceDemo()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Refresh'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Completed read 2'), findsOneWidget);
    expect(find.text('Completed read 1'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
