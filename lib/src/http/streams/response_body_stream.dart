import 'dart:async';

/// A single-subscription stream with explicit cleanup even before listening.
class ResponseBodyStream extends Stream<List<int>> {
  ResponseBodyStream(this._source, {FutureOr<void> Function()? onClose})
      : _onClose = onClose {
    _controller = StreamController<List<int>>(
      onListen: _start,
      onPause: () => _subscription?.pause(),
      onResume: () => _subscription?.resume(),
      onCancel: cancel,
    );
  }
  final Stream<List<int>> _source;
  final FutureOr<void> Function()? _onClose;
  late final StreamController<List<int>> _controller;
  StreamSubscription<List<int>>? _subscription;
  Future<void>? _closing;
  bool _started = false;
  void _start() {
    if (_closing != null) return;
    _started = true;
    _subscription = _source.listen(_controller.add,
        onError: (Object error, StackTrace stack) {
      _controller.addError(error, stack);
      unawaited(cancel());
    }, onDone: () {
      unawaited(_finish());
    }, cancelOnError: true);
  }

  Future<void> _finish() {
    return _closing ??= Future<void>.sync(() async {
      try {
        await _onClose?.call();
      } finally {
        unawaited(_controller.close());
      }
    });
  }

  Future<void> abort(Object error) {
    if (_closing != null) return _closing!;
    _controller.addError(error);
    return cancel();
  }

  Future<void> cancel() {
    if (_closing != null) return _closing!;
    return _closing = Future<void>.sync(() async {
      try {
        if (_started) {
          await _subscription?.cancel();
        } else {
          await _source.listen(null).cancel();
        }
      } finally {
        try {
          await _onClose?.call();
        } finally {
          unawaited(_controller.close());
        }
      }
    });
  }

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
