import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final first = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final second = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final origin = 'http://127.0.0.1:${first.port}';
  Future<void> handle(HttpRequest request) async {
    final response = request.response;
    response.headers.set('access-control-allow-origin', origin);
    response.headers.set('access-control-allow-credentials', 'true');
    response.headers
        .set('access-control-allow-headers', 'content-type,x-xsrf-token');
    response.headers.set('access-control-allow-methods', 'GET,POST,OPTIONS');
    if (request.method == 'OPTIONS') {
      response.statusCode = 204;
      await response.close();
      return;
    }
    switch (request.uri.path) {
      case '/':
        response.headers.contentType = ContentType.html;
        response.headers
            .add('set-cookie', 'XSRF-TOKEN=test-token; Path=/; SameSite=Lax');
        final wasm = request.uri.queryParameters.containsKey('wasm');
        response.write(wasm
            ? """<!doctype html><body><script type="module">
import * as runtime from '/main.mjs';
try {
  if (runtime.compileStreaming) {
    const app = await runtime.compileStreaming(fetch('/main.wasm'));
    const instance = await app.instantiate({});
    instance.invokeMain();
  } else {
    const instance = await runtime.instantiate(
      WebAssembly.compileStreaming(fetch('/main.wasm')), {});
    runtime.invoke(instance);
  }
} catch (error) {
  document.body.setAttribute('data-result', 'FAIL loader: ' + error);
}
</script></body>"""
            : '<!doctype html><body><script defer src="/main.js"></script></body>');
      case '/config':
        response.headers.contentType = ContentType.json;
        response
            .write(jsonEncode({'cross': 'http://127.0.0.1:${second.port}'}));
      case '/echo':
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({
          'body': await utf8.decoder.bind(request).join(),
          'xsrf': request.headers.value('x-xsrf-token')
        }));
      case '/stream':
        response.write('first');
        await response.flush();
        await Future<void>.delayed(const Duration(seconds: 2));
        response.write('second');
      case '/ws':
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen(socket.add, onDone: socket.close);
        return;
      default:
        final name = request.uri.path.substring(1);
        if (!{'main.js', 'main.js.map', 'main.mjs', 'main.wasm'}
            .contains(name)) {
          response.statusCode = 404;
          break;
        }
        response.headers.contentType = name.endsWith('.wasm')
            ? ContentType('application', 'wasm')
            : ContentType('application', 'javascript');
        await response.addStream(File('build/browser/$name').openRead());
    }
    await response.close();
  }

  first.listen((request) {
    unawaited(handle(request).catchError((Object error) {
      request.response.close();
    }));
  });
  second.listen((request) {
    unawaited(handle(request).catchError((Object error) {
      request.response.close();
    }));
  });
  stdout.writeln(origin);
}
