import 'dart:collection';
import '../../../core/cancellation/cancellation_token.dart';
import '../../../http/middleware/contracts/http_middleware.dart';
import '../../../http/middleware/contracts/http_request_handler.dart';
import '../../../http/models/http_request.dart';
import '../../../http/models/http_response.dart';
import '../models/queued_permit.dart';

/// Permits cover the response lifetime, not just the time to receive headers.
class ConcurrencyInterceptor implements HttpMiddleware {
  ConcurrencyInterceptor({this.maxConcurrent = 6, this.maxQueued = 100}) {
    if (maxConcurrent < 1 || maxQueued < 0) {
      throw ArgumentError('Invalid concurrency limits.');
    }
  }
  final int maxConcurrent;
  final int maxQueued;
  int _active = 0;
  final Queue<QueuedPermit> _queue = Queue();
  Future<void> _acquire(CancellationToken token) async {
    token.throwIfCanceled();
    if (_active < maxConcurrent) {
      _active++;
      return;
    }
    if (_queue.length >= maxQueued) throw StateError('Request queue is full.');
    final pending = QueuedPermit();
    _queue.add(pending);
    pending.removeCancellation = token.onCancel(() {
      if (!_queue.remove(pending)) return;
      pending.ready.completeError(token.error);
    });
    await pending.ready.future;
  }

  void _release() {
    if (_queue.isEmpty) {
      _active--;
      return;
    }
    final pending = _queue.removeFirst();
    pending.removeCancellation();
    pending.ready.complete();
  }

  @override
  Future<HttpResponse> intercept(HttpRequest request, CancellationToken token,
      HttpRequestHandler next) async {
    await _acquire(token);
    try {
      token.throwIfCanceled();
      final response = await next(request, token);
      return response.withBody(response.body, onClose: _release);
    } catch (_) {
      _release();
      rethrow;
    }
  }
}
