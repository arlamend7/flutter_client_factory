import '../../core/cancellation/cancellation_token.dart';
import '../../http/models/http_request.dart';
import '../../http/models/http_response.dart';
import '../../transports/contracts/http_transport.dart';
import '../models/pending_request.dart';

/// Captures HTTP work for deterministic request assertions without networking.
/// Matching alone does not complete a request; use flush/fail and then verify.
class HttpTestingController implements HttpTransport {
  final List<PendingRequest> _pending = [];
  bool _closed = false;
  List<PendingRequest> match(bool Function(HttpRequest) predicate) {
    final matches = _pending
        .where((item) => !item.matched && predicate(item.request))
        .toList();
    for (final item in matches) {
      item.matched = true;
    }
    return List.unmodifiable(matches);
  }

  /// Matches exactly one previously unmatched request by complete URI string.
  PendingRequest expectOne(String url) {
    final candidates = _pending
        .where((item) => !item.matched && item.request.uri.toString() == url)
        .toList();
    if (candidates.length != 1) {
      throw StateError(
          'Expected one request to $url, found ${candidates.length}.');
    }
    candidates.single.matched = true;
    return candidates.single;
  }

  void expectNone(String url) {
    if (_pending
        .any((item) => !item.matched && item.request.uri.toString() == url)) {
      throw StateError('Unexpected request to $url.');
    }
  }

  /// Throws if a request is unmatched or incomplete, optionally ignoring canceled work.
  void verify({bool ignoreCanceled = false}) {
    final outstanding = _pending
        .where((item) =>
            !(ignoreCanceled && item.token.isCanceled) &&
            (!item.matched || !item.completed))
        .length;
    if (outstanding > 0) throw StateError('$outstanding unhandled requests.');
  }

  @override
  Future<HttpResponse> send(HttpRequest request, CancellationToken token) {
    if (_closed) throw StateError('Testing controller closed.');
    token.throwIfCanceled();
    final pending = PendingRequest(request, token);
    _pending.add(pending);
    return pending.response;
  }

  @override
  Future<void> close() async {
    _closed = true;
    for (final pending in _pending) {
      if (!pending.completed) {
        pending.fail(StateError('Testing controller closed.'));
      }
    }
  }
}
