import 'dart:js_interop';

@JS('WebSocket')
extension type BrowserWebSocket._(JSObject _) implements JSObject {
  external BrowserWebSocket(String url, JSArray<JSString> protocols);
  external int get readyState;
  external set binaryType(String value);
  external set onopen(JSFunction? callback);
  external set onmessage(JSFunction? callback);
  external set onerror(JSFunction? callback);
  external set onclose(JSFunction? callback);
  external void send(JSAny message);
  external void close([int code, String reason]);
}
