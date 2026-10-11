import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_client/resources.dart';
import 'package:flutter_client_widgets/flutter_client_widgets.dart';
import 'resource_demo.dart';

class ResourceDemoState extends State<ResourceDemo> {
  late final HttpResourceNotifier<String> _notifier;
  int _reads = 0;
  @override
  void initState() {
    super.initState();
    _notifier = HttpResourceNotifier(HttpResource((token) async {
      final read = ++_reads;
      await token.wait(const Duration(milliseconds: 500));
      return 'Completed read $read';
    }));
    unawaited(_notifier.refresh());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cancellable resource')),
        body: Center(
            child: ValueListenableBuilder<ResourceState<String>>(
          valueListenable: _notifier,
          builder: (context, state, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isLoading) const CircularProgressIndicator(),
              Text(state.error == null
                  ? state.data ?? 'Waiting'
                  : 'Read failed'),
              FilledButton(
                  onPressed: () => unawaited(_notifier.refresh()),
                  child: const Text('Refresh')),
            ],
          ),
        )),
      );
  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }
}
