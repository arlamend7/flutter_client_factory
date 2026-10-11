import 'dart:js_interop';

@JS('Headers')
extension type BrowserHeaders._(JSObject _) implements JSObject {
  external BrowserHeaders();
  external void append(String name, String value);
  external void forEach(JSFunction callback);
}
