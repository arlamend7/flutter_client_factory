import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import '../../../core/cancellation/cancellation_token.dart';
import '../../../core/errors/network_exception.dart';
import '../../../http/enums/http_method.dart';
import '../../../http/models/http_headers.dart';
import '../../../http/models/http_request.dart';
import '../../../http/models/http_response.dart';
import '../../contracts/http_transport.dart';
import '../configuration/web_transport_options.dart';
import '../interop/browser_abort_controller.dart';
import '../interop/browser_fetch.dart';
import '../interop/browser_headers.dart';
import '../interop/browser_request_init.dart';
import '../interop/browser_stream_reader.dart';

/// Fetch transport: streaming responses, bounded buffered uploads, no socket controls.
class WebHttpTransport implements HttpTransport {
  WebHttpTransport({WebTransportOptions? options})
      : options = options ?? WebTransportOptions();
  final WebTransportOptions options;
  final Set<CancellationToken> _active = {};
  bool _closed = false;
  @override
  Future<HttpResponse> send(
      HttpRequest request, CancellationToken parent) async {
    if (_closed) throw StateError('Transport closed.');
    parent.throwIfCanceled();
    if (request.body != null &&
        {HttpMethod.get, HttpMethod.head}.contains(request.method)) {
      throw UnsupportedError('Browser Fetch cannot send GET/HEAD bodies.');
    }
    final token = CancellationToken.linked([parent]);
    final controller = BrowserAbortController();
    _active.add(token);
    HttpResponse? response;
    final remove = token.onCancel(() {
      controller.abort();
      final current = response;
      if (current != null) unawaited(current.body.abort(token.error));
    });
    void finish() {
      remove();
      token.dispose();
      _active.remove(token);
    }

    try {
      final headers = BrowserHeaders();
      request.headers.values.forEach((name, values) {
        if ({
              'host',
              'content-length',
              'connection',
              'cookie',
              'set-cookie',
              'transfer-encoding',
              'accept-encoding',
              'origin',
              'referer'
            }.contains(name) ||
            name.startsWith('sec-') ||
            name.startsWith('proxy-')) {
          throw UnsupportedError('Browser controls the "$name" header.');
        }
        for (final value in values) {
          headers.append(name, value);
        }
      });
      final cookieName = options.xsrfCookieName;
      if (cookieName != null &&
          request.uri.origin == browserOrigin &&
          !{HttpMethod.get, HttpMethod.head, HttpMethod.options}
              .contains(request.method)) {
        for (final cookie in browserCookies.split(';')) {
          final pair = cookie.trim();
          if (pair.startsWith('$cookieName=')) {
            headers.append(options.xsrfHeaderName,
                Uri.decodeComponent(pair.substring(cookieName.length + 1)));
          }
        }
      }
      JSUint8Array? payload;
      final body = request.body;
      if (body != null) {
        final length = body.contentLength;
        if (length == null || length < 0 || length > options.maxUploadBytes) {
          throw UnsupportedError(
              'Browser uploads require a known length within maxUploadBytes.');
        }
        final bytes = BytesBuilder();
        final chunks = StreamIterator(body.openRead());
        try {
          while (await token.race(chunks.moveNext())) {
            token.throwIfCanceled();
            final chunk = chunks.current;
            if (bytes.length + chunk.length > options.maxUploadBytes) {
              throw StateError('Upload limit exceeded.');
            }
            bytes.add(chunk);
          }
        } finally {
          await chunks.cancel();
        }
        if (bytes.length != length) {
          throw StateError('Upload body does not match its declared length.');
        }
        payload = bytes.takeBytes().toJS;
      }
      final incoming = await token.race(browserFetch(
              request.uri.toString(),
              BrowserRequestInit(
                  method: request.method.value,
                  headers: headers,
                  body: payload,
                  signal: controller.signal,
                  credentials: options.credentials,
                  redirect: options.redirect,
                  cache: options.cache,
                  mode: 'cors',
                  referrerPolicy: options.referrerPolicy))
          .toDart);
      if (incoming.status == 0) {
        throw UnsupportedError(
            'Opaque browser responses cannot expose HTTP data.');
      }
      final values = <String, List<String>>{};
      incoming.headers
          .forEach(((JSString value, JSString name, JSAny? headers) {
        values[name.toDart] = [value.toDart];
      }).toJS);
      final reader = incoming.body?.getReader();
      response = HttpResponse(
          statusCode: incoming.status,
          uri: Uri.parse(incoming.url),
          headers: HttpHeaders(values),
          body: _read(reader, token),
          onClose: () async {
            try {
              await reader?.cancel().toDart;
            } catch (_) {
              // An already-aborted Fetch stream can reject cancel(). The body
              // carries the original cancellation/timeout; cleanup must not
              // replace it with a browser AbortError.
              if (!token.isCanceled) rethrow;
            } finally {
              reader?.releaseLock();
              finish();
            }
          });
      token.throwIfCanceled();
      return response;
    } catch (error, stack) {
      controller.abort();
      if (response != null) await response.dispose();
      finish();
      if (token.isCanceled) Error.throwWithStackTrace(token.error, stack);
      if (error is ArgumentError ||
          error is UnsupportedError ||
          error is StateError) {
        rethrow;
      }
      Error.throwWithStackTrace(
          NetworkException(request.uri, error, stack), stack);
    }
  }

  Stream<List<int>> _read(
      BrowserStreamReader? reader, CancellationToken token) async* {
    if (reader == null) return;
    try {
      while (true) {
        token.throwIfCanceled();
        final chunk = await token.race(reader.read().toDart);
        if (chunk.done) return;
        final value = chunk.value;
        if (value != null) yield value.toDart;
      }
    } catch (error, stack) {
      if (token.isCanceled) Error.throwWithStackTrace(token.error, stack);
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final token in _active.toList()) {
      token.cancel('Transport closed.');
    }
  }
}
