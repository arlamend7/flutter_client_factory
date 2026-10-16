import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/resources.dart';
import 'package:flutter_client_factory_widgets/flutter_client_factory_widgets.dart';
import 'models/user_summary.dart';
import 'resource_demo.dart';

class ResourceDemoState extends State<ResourceDemo> {
  late final HttpResourceNotifier<UserSummary> _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = HttpResourceNotifier.fromLoader(_loadUser);
    unawaited(_notifier.refresh());
  }

  Future<UserSummary> _loadUser(CancellationToken token) async {
    final response = await widget.users.getUser(1, cancellationToken: token);
    if (!response.isSuccessful) {
      await response.dispose();
      throw HttpStatusException(response.statusCode,
          headers: response.headers, uri: response.uri);
    }
    return response.readJson(decode: UserSummary.fromJson);
  }

  @override
  void didUpdateWidget(covariant ResourceDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.users, widget.users)) return;
    unawaited(_notifier.refresh());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('User profile')),
        body: Center(
          child: ValueListenableBuilder<ResourceState<UserSummary>>(
            valueListenable: _notifier,
            builder: (context, state, child) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.isLoading) const CircularProgressIndicator(),
                if (state.error != null)
                  const Text('Could not load the user. Please try again.'),
                if (state.data != null) Text('Hello, ${state.data!.name}'),
                if (!state.isLoading &&
                    state.error == null &&
                    state.data == null)
                  const Text('No user loaded yet.'),
                FilledButton(
                  onPressed: () => unawaited(_notifier.refresh()),
                  child: Text(state.error == null ? 'Refresh' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  void dispose() {
    // Cancels the owned resource's pending request before releasing listeners.
    _notifier.dispose();
    super.dispose();
  }
}
