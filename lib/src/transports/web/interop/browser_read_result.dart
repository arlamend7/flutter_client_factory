import 'dart:js_interop';

extension type BrowserReadResult._(JSObject _) implements JSObject {
  external bool get done;
  external JSUint8Array? get value;
}
