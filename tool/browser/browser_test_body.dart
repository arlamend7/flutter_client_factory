import 'dart:js_interop';

extension type BrowserTestBody._(JSObject _) implements JSObject {
  external void setAttribute(String name, String value);
}
@JS('document.body')
external BrowserTestBody get testBody;
@JS('location.origin')
external String get testOrigin;
