import 'dart:async';
import '../../../core/cancellation/cancellation_token.dart';
import '../../../http/models/http_request.dart';
import '../../../http/models/http_response.dart';
import '../../../transports/contracts/http_transport.dart';

class TransportLease {
  TransportLease(this.transport, this.createdAt);
  final HttpTransport transport;
  final DateTime createdAt;
  final Completer<void> _drained = Completer<void>();
  int _active = 0;
  bool _retired = false;
  Future<void>? _closing;
  Future<HttpResponse> send(
      HttpRequest request, CancellationToken token) async {
    if (_retired) throw StateError('Transport retired.');
    _active++;
    try {
      final response = await transport.send(request, token);
      return response.withBody(response.body, onClose: _release);
    } catch (_) {
      _release();
      rethrow;
    }
  }

  void _release() {
    _active--;
    if (_retired && _active == 0 && !_drained.isCompleted) _drained.complete();
  }

  Future<void> retire(Duration grace) {
    if (_closing != null) return _closing!;
    _retired = true;
    if (_active == 0) _drained.complete();
    return _closing = Future<void>.sync(() async {
      try {
        await _drained.future.timeout(grace);
      } on TimeoutException {
        /* Transport close enforces its own abort policy. */
      }
      await transport.close();
    });
  }
}
