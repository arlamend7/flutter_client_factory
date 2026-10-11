import 'dart:async';
import '../../core/cancellation/cancellation_token.dart';
import '../../factory/configuration/http_client_registration_builder.dart';
import '../../http/contracts/http_client.dart';
import '../../http/enums/http_method.dart';
import '../../http/middleware/contracts/http_interceptor.dart';
import '../../http/models/http_request.dart';
import '../../http/models/http_response.dart';
import '../../http/services/http_client_service.dart';
import '../../transports/contracts/http_transport.dart';
import '../models/pending_request.dart';

/// Captures HTTP work for deterministic request assertions without networking.
/// Matching alone does not complete a request; use flush/fail and then verify.
class HttpTestingController implements HttpTransport {
  final List<PendingRequest> _pending = [];
  bool _closed = false;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Creates a borrowed client. The test owns this controller and must close it.
  HttpClient createClient(
      {String? baseUrl,
      Map<String, String> defaultHeaders = const {},
      List<HttpInterceptor> interceptors = const [],
      Duration? timeout}) {
    if (_closed) throw StateError('Testing controller closed.');
    final options = HttpClientRegistrationBuilder(
            baseUrl: baseUrl,
            defaultHeaders: defaultHeaders,
            interceptors: interceptors,
            timeout: timeout)
        .build()
        .options;
    return HttpClientService(transport: this, options: options);
  }

  String get _outstanding => _pending
      .where((item) => !item.matched || !item.completed)
      .map((item) => '${item.request.method.value} ${item.request.uri}'
          ' (${item.matched ? "matched" : "unmatched"}, '
          '${item.completed ? "completed" : "pending"})')
      .join(', ');

  List<PendingRequest> match(bool Function(HttpRequest) predicate) {
    final matches = _pending
        .where((item) => !item.matched && predicate(item.request))
        .toList();
    for (final item in matches) {
      item.matched = true;
    }
    return List.unmodifiable(matches);
  }

  /// Matches one request by full URL (including query) and optional method.
  PendingRequest expectOne(String url, {HttpMethod? method}) => expectOneWhere(
      (request) =>
          request.uri.toString() == url &&
          (method == null || request.method == method),
      description: '${method?.value ?? "ANY"} $url');

  /// Matches exactly one request without consuming candidates on failure.
  PendingRequest expectOneWhere(bool Function(HttpRequest) predicate,
      {String description = 'matching request'}) {
    final candidates = _pending
        .where((item) => !item.matched && predicate(item.request))
        .toList();
    if (candidates.length != 1) {
      throw StateError('Expected one $description, found ${candidates.length}. '
          'Outstanding: $_outstanding');
    }
    candidates.single.matched = true;
    return candidates.single;
  }

  void expectNone(String url, {HttpMethod? method}) {
    if (_pending.any((item) =>
        !item.matched &&
        item.request.uri.toString() == url &&
        (method == null || item.request.method == method))) {
      throw StateError('Unexpected ${method?.value ?? "ANY"} $url. '
          'Outstanding: $_outstanding');
    }
  }

  /// Waits for middleware-delayed requests without sleeps or polling.
  /// Matching reserves the request; flush/fail it and verify after awaiting work.
  Future<PendingRequest> waitForOne(String url,
          {HttpMethod? method,
          Duration timeout = const Duration(seconds: 5)}) =>
      waitForOneWhere(
          (request) =>
              request.uri.toString() == url &&
              (method == null || request.method == method),
          timeout: timeout,
          description: '${method?.value ?? "ANY"} $url');

  /// Event-driven predicate matching with a bounded wait and diagnostic failure.
  Future<PendingRequest> waitForOneWhere(bool Function(HttpRequest) predicate,
      {Duration timeout = const Duration(seconds: 5),
      String description = 'matching request'}) async {
    if (timeout <= Duration.zero) throw ArgumentError.value(timeout, 'timeout');
    final result = Completer<PendingRequest>();
    void check() {
      if (result.isCompleted) return;
      try {
        if (_closed) throw StateError('Testing controller closed.');
        final candidates = _pending
            .where((item) => !item.matched && predicate(item.request))
            .toList();
        if (candidates.isEmpty) return;
        if (candidates.length != 1) {
          throw StateError(
              'Expected one $description, found ${candidates.length}. '
              'Outstanding: $_outstanding');
        }
        candidates.single.matched = true;
        result.complete(candidates.single);
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    }

    final subscription = _changes.stream.listen((_) => check());
    final timer = Timer(timeout, () {
      if (result.isCompleted) return;
      result.completeError(TimeoutException(
          'Waiting for $description. '
          'Outstanding: $_outstanding',
          timeout));
    });
    check();
    try {
      return await result.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
    }
  }

  /// Throws if a request is unmatched or incomplete, optionally ignoring canceled work.
  void verify({bool ignoreCanceled = false}) {
    final outstanding = _pending
        .where((item) =>
            !(ignoreCanceled && item.token.isCanceled) &&
            (!item.matched || !item.completed))
        .length;
    if (outstanding > 0) {
      throw StateError(
          '$outstanding unhandled requests. Outstanding: $_outstanding');
    }
  }

  @override
  Future<HttpResponse> send(HttpRequest request, CancellationToken token) {
    if (_closed) throw StateError('Testing controller closed.');
    token.throwIfCanceled();
    final pending = PendingRequest(request, token);
    _pending.add(pending);
    _changes.add(null);
    return pending.response;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _changes.add(null);
    for (final pending in _pending) {
      if (!pending.completed) {
        pending.fail(StateError('Testing controller closed.'));
      }
    }
    await _changes.close();
  }
}
