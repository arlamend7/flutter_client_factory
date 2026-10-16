import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_client_factory/diagnostics.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'client_example_app.dart';
import 'resource_demo.dart';
import 'services/users_service.dart';

class ClientExampleAppState extends State<ClientExampleApp> {
  final _factory = DefaultHttpClientFactory();
  late final HttpClient _client;
  late final UsersService _users;

  @override
  void initState() {
    super.initState();
    final logging = DiagnosticsInterceptor((event) => debugPrint('$event'));
    _factory.registerClient('api',
        baseUrl: 'https://jsonplaceholder.typicode.com/',
        defaultHeaders: {'Accept': 'application/json'},
        timeout: const Duration(seconds: 10),
        interceptors: [logging.intercept]);
    _client = _factory.create('api');
    _users = UsersService(client: _client);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'HTTP resource example', home: ResourceDemo(users: _users));

  @override
  void dispose() {
    _client.dispose();
    // Flutter's dispose is synchronous; the app owns asynchronous shutdown.
    unawaited(_factory.close());
    super.dispose();
  }
}
