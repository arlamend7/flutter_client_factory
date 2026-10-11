import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart'
    show CancellationToken;
import 'package:flutter_client_factory/resources.dart';

/// Owns its resource by default. Call refresh when inputs change.
class HttpResourceNotifier<T> extends ValueNotifier<ResourceState<T>> {
  /// Starts observing [resource] and optionally owns its disposal.
  HttpResourceNotifier(this.resource, {this.ownsResource = true})
      : super(resource.state) {
    _subscription = resource.changes.listen((state) {
      value = state;
    });
  }

  /// Creates and owns a resource for this loader. Call refresh to start loading.
  HttpResourceNotifier.fromLoader(
      Future<T> Function(CancellationToken token) load)
      : this(HttpResource<T>(load));

  /// The independently testable Dart resource exposed to Flutter listeners.
  final HttpResource<T> resource;

  /// Whether disposing this notifier also cancels and disposes [resource].
  final bool ownsResource;
  late final StreamSubscription<ResourceState<T>> _subscription;

  /// Starts a new read, canceling any superseded resource load.
  Future<void> refresh() => resource.refresh();
  @override
  void dispose() {
    unawaited(_subscription.cancel());
    if (ownsResource) unawaited(resource.dispose());
    super.dispose();
  }
}
