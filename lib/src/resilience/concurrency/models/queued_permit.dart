import 'dart:async';

class QueuedPermit {
  final Completer<void> ready = Completer<void>();
  void Function() removeCancellation = () {};
}
