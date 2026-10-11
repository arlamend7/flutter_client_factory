import 'dart:js_interop';

@JS('AbortController')
extension type BrowserAbortController._(JSObject _) implements JSObject {
  external BrowserAbortController();
  external JSObject get signal;
  external void abort();
}
