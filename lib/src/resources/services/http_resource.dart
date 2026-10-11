import 'dart:async';
import '../../core/cancellation/cancellation_token.dart';
import '../models/resource_state.dart';

/// Explicit refresh for reads. Superseded results can never replace current state.
class HttpResource<T> {
  HttpResource(this.load);
  final Future<T> Function(CancellationToken token) load;
  final StreamController<ResourceState<T>> _changes =
      StreamController.broadcast();
  ResourceState<T> _state = ResourceState<T>();
  CancellationToken? _current;
  int _generation = 0;
  bool _disposed = false;
  ResourceState<T> get state => _state;
  Stream<ResourceState<T>> get changes => _changes.stream;
  void _publish(ResourceState<T> state) {
    _state = state;
    _changes.add(state);
  }

  /// Cancels the previous load and publishes only this generation's result.
  Future<void> refresh() async {
    if (_disposed) throw StateError('Resource disposed.');
    _current?.cancel('Superseded by a newer read.');
    final token = CancellationToken();
    _current = token;
    final generation = ++_generation;
    _publish(ResourceState<T>(data: _state.data, isLoading: true));
    try {
      final data = await token.race(Future<T>.sync(() => load(token)));
      if (_disposed || generation != _generation) return;
      _publish(ResourceState<T>(data: data));
    } catch (error, stack) {
      if (_disposed || generation != _generation) return;
      _publish(
          ResourceState<T>(data: _state.data, error: error, stackTrace: stack));
    } finally {
      token.dispose();
    }
  }

  /// Cancels current loading and closes state notifications idempotently.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _current?.cancel('Resource disposed.');
    await _changes.close();
  }
}
