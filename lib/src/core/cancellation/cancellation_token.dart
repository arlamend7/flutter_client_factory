import 'dart:async';
import '../errors/request_canceled_exception.dart';

/// Cancelable operations subscribe with [onCancel] and remove their listener.
class CancellationToken {
  CancellationToken();

  /// Creates a child canceled by any parent; dispose the child to detach listeners.
  factory CancellationToken.linked(Iterable<CancellationToken> parents) {
    final child = CancellationToken();
    for (final parent in parents) {
      child._detach.add(parent.onCancel(() => child.cancelWith(parent.error)));
    }
    return child;
  }
  final Completer<void> _completion = Completer<void>();
  final Set<void Function()> _listeners = {};
  final List<void Function()> _detach = [];
  Object? _error;

  /// Whether a cancellation reason has been recorded. Cancellation is one-shot.
  bool get isCanceled => _error != null;
  Object get error => _error ?? const RequestCanceledException();
  String? get reason => _error is RequestCanceledException
      ? (_error as RequestCanceledException).reason
      : _error?.toString();
  Future<void> get whenCanceled => _completion.future;

  /// Signals cancellation once; repeated calls preserve the original reason.
  void cancel([String? reason]) => cancelWith(RequestCanceledException(reason));

  /// Signals an explicit terminal error, for example a timeout.
  void cancelWith(Object error) {
    if (isCanceled) return;
    _error = error;
    _completion.complete();
    final listeners = _listeners.toList();
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
    dispose();
  }

  /// Registers a non-throwing callback and returns its removal function.
  /// Already canceled tokens invoke the callback immediately.
  void Function() onCancel(void Function() listener) {
    if (isCanceled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void throwIfCanceled() {
    if (isCanceled) throw error;
  }

  /// Stops waiting when canceled; the operation must implement its own resource abort.
  Future<T> race<T>(Future<T> work) async {
    final canceled = Completer<T>();
    final remove = onCancel(() => canceled.completeError(error));
    try {
      return await Future.any([work, canceled.future]);
    } finally {
      remove();
    }
  }

  /// Waits a duration with a timer that is canceled when this token is canceled.
  Future<void> wait(Duration duration) async {
    throwIfCanceled();
    final done = Completer<void>();
    final timer = Timer(duration, done.complete);
    try {
      await race(done.future);
    } finally {
      timer.cancel();
    }
  }

  /// Detaches linked parents. Does not cancel this token.
  void dispose() {
    for (final remove in _detach) {
      remove();
    }
    _detach.clear();
  }
}
