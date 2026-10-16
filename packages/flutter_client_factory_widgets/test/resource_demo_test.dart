import 'package:flutter/material.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import '../example/lib/resource_demo.dart';
import '../example/lib/services/users_service.dart';

void main() {
  late HttpTestingController testing;
  late HttpClient client;
  late UsersService users;

  setUp(() {
    testing = HttpTestingController();
    client = testing.createClient(baseUrl: 'https://example.test/');
    users = UsersService(client: client);
  });
  tearDown(() async {
    try {
      testing.verify();
    } finally {
      client.dispose();
      await testing.close();
    }
  });

  testWidgets('shows loading, typed data and refreshed data', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ResourceDemo(users: users)));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    (testing.expectOne('https://example.test/users/1'))
        .flushJson({'id': 1, 'name': 'Ada'});
    await tester.pumpAndSettle();
    expect(find.text('Hello, Ada'), findsOneWidget);
    await tester.tap(find.text('Refresh'));
    await tester.pump();
    (testing.expectOne('https://example.test/users/1'))
        .flushJson({'id': 1, 'name': 'Grace'});
    await tester.pumpAndSettle();
    expect(find.text('Hello, Grace'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('HTTP failure shows retry and can recover', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ResourceDemo(users: users)));
    await tester.pump();
    (testing.expectOne('https://example.test/users/1'))
        .flushText('Unavailable', statusCode: 503);
    await tester.pump();
    // Let the SDK's stream-cancellation future complete outside fake time.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Could not load the user. Please try again.'),
        findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    (testing.expectOne('https://example.test/users/1'))
        .flushJson({'id': 1, 'name': 'Ada'});
    await tester.pumpAndSettle();
    expect(find.text('Hello, Ada'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('refresh and widget disposal cancel pending requests',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: ResourceDemo(users: users)));
    await tester.pump();
    final first = testing.expectOne('https://example.test/users/1');
    await tester.tap(find.text('Refresh'));
    await tester.pump();
    final second = testing.expectOne('https://example.test/users/1');
    expect(first.token.isCanceled, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(second.token.isCanceled, isTrue);
    expect(tester.takeException(), isNull);
  });
}
