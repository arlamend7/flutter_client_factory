import 'dart:async';
import 'dart:io' as io;
import '../../../core/cancellation/cancellation_token.dart';
import '../../../core/errors/network_exception.dart';
import '../../../core/errors/request_timeout_exception.dart';
import '../../../http/enums/http_method.dart';
import '../../../http/models/http_headers.dart';
import '../../../http/models/http_request.dart';
import '../../../http/models/http_response.dart';
import '../../contracts/http_transport.dart';
import '../configuration/io_transport_options.dart';

/// SDK HTTP(S) transport with pooling, streaming and request-local cancellation.
/// Cross-origin redirects strip credentials and HTTPS downgrades are rejected.
class IoHttpTransport implements HttpTransport {
  IoHttpTransport({IoTransportOptions options = const IoTransportOptions()})
      : _options = options,
        _client = io.HttpClient(context: options.securityContext) {
    if (options.maxConnectionsPerHost < 1 ||
        options.maxRedirects < 0 ||
        options.connectionTimeout <= Duration.zero ||
        options.shutdownTimeout < Duration.zero) {
      throw ArgumentError('Invalid native transport limits.');
    }
    _client.connectionTimeout = options.connectionTimeout;
    _client.idleTimeout = options.idleTimeout;
    _client.maxConnectionsPerHost = options.maxConnectionsPerHost;
    _client.autoUncompress = options.autoUncompress;
    if (options.findProxy != null) _client.findProxy = options.findProxy;
  }
  final IoTransportOptions _options;
  final io.HttpClient _client;
  final Map<CancellationToken, Completer<void>> _active = {};
  Future<void>? _closing;
  @override
  Future<HttpResponse> send(
      HttpRequest request, CancellationToken cancellationToken) async {
    var current = request;
    for (var redirect = 0;; redirect++) {
      final response = await _sendOnce(current, cancellationToken);
      if (!_options.followRedirects ||
          !{301, 302, 303, 307, 308}.contains(response.statusCode)) {
        return response;
      }
      final locations = response.headers['location'];
      if (locations.isEmpty) return response;
      if (redirect >= _options.maxRedirects) {
        await response.dispose();
        throw StateError('Maximum redirects exceeded.');
      }
      final toGet =
          response.statusCode == 303 && current.method != HttpMethod.head;
      if (!toGet && current.body?.isReplayable == false) return response;
      if ({301, 302}.contains(response.statusCode) &&
          !{HttpMethod.get, HttpMethod.head}.contains(current.method)) {
        return response;
      }
      Uri target;
      try {
        target = current.uri.resolve(locations.first);
      } catch (_) {
        await response.dispose();
        rethrow;
      }
      if (!{'http', 'https'}.contains(target.scheme) ||
          target.host.isEmpty ||
          target.userInfo.isNotEmpty ||
          (current.uri.scheme == 'https' && target.scheme == 'http')) {
        await response.dispose();
        throw StateError('Unsafe redirect destination.');
      }
      var headers = current.headers;
      if (target.origin != current.uri.origin) {
        headers =
            headers.without(['authorization', 'proxy-authorization', 'cookie']);
      }
      if (toGet) {
        headers = headers
            .without(['content-type', 'content-length', 'transfer-encoding']);
      }
      current = current.copyWith(
          uri: target,
          headers: headers,
          method: toGet ? HttpMethod.get : current.method,
          removeBody: toGet);
      await response.dispose();
    }
  }

  Future<HttpResponse> _sendOnce(
      HttpRequest request, CancellationToken cancellationToken) async {
    if (_closing != null) throw StateError('Transport closed.');
    cancellationToken.throwIfCanceled();
    final token = CancellationToken.linked([cancellationToken]);
    final done = Completer<void>();
    _active[token] = done;
    io.HttpClientRequest? outgoing;
    HttpResponse? response;
    var finished = false;
    void Function() remove = () {};
    void finish() {
      if (finished) return;
      finished = true;
      remove();
      token.dispose();
      _active.remove(token);
      done.complete();
    }

    remove = token.onCancel(() {
      outgoing?.abort(token.error);
      final current = response;
      if (current != null) unawaited(current.body.abort(token.error));
    });
    try {
      final opening = _client.openUrl(request.method.value, request.uri);
      // An opening socket has no request handle yet. Abort as soon as it exists.
      unawaited(opening.then<void>((value) {
        if (!token.isCanceled) return;
        unawaited(value.done
            .then<void>((_) {}, onError: (Object e, StackTrace s) {}));
        value.abort(token.error);
      }, onError: (Object e, StackTrace s) {}));
      final native = await token.race(opening);
      outgoing = native;
      unawaited(
          native.done.then<void>((_) {}, onError: (Object e, StackTrace s) {}));
      native.followRedirects = false;
      native.maxRedirects = _options.maxRedirects;
      request.headers.values
          .forEach((name, values) => native.headers.set(name, values));
      final body = request.body;
      if (body != null) {
        if (body.contentLength != null) {
          native.contentLength = body.contentLength!;
        }
        await token.race(native.addStream(body.openRead()));
      }
      final incoming = await token.race(native.close());
      final headers = <String, List<String>>{};
      incoming.headers.forEach((name, values) => headers[name] = values);
      Stream<List<int>> stream =
          incoming.handleError((Object error, StackTrace stack) {
        Error.throwWithStackTrace(
            NetworkException(request.uri, error, stack), stack);
      }, test: (Object? error) => error is io.IOException);
      final idle = _options.responseIdleTimeout;
      if (idle != null) {
        stream = stream.timeout(idle, onTimeout: (sink) {
          final error = RequestTimeoutException(idle, phase: 'response idle');
          sink.addError(error);
          sink.close();
        });
      }
      response = HttpResponse(
          statusCode: incoming.statusCode,
          headers: HttpHeaders(headers),
          uri: request.uri,
          body: stream,
          onClose: finish);
      if (token.isCanceled) {
        await response.dispose();
        token.throwIfCanceled();
      }
      return response;
    } catch (error, stack) {
      outgoing?.abort(error, stack);
      finish();
      if (token.isCanceled) Error.throwWithStackTrace(token.error, stack);
      if (error is io.IOException) {
        Error.throwWithStackTrace(
            NetworkException(request.uri, error, stack), stack);
      }
      rethrow;
    }
  }

  @override
  Future<void> close() {
    return _closing ??= Future<void>.microtask(() async {
      _client.close();
      final timer = Timer(_options.shutdownTimeout, () {
        for (final token in _active.keys.toList()) {
          token.cancel('Transport shutdown.');
        }
        _client.close(force: true);
      });
      try {
        await Future.wait(_active.values.map((done) => done.future).toList());
      } finally {
        timer.cancel();
        _client.close(force: true);
      }
    });
  }
}
