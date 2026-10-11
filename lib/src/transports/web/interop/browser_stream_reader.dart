import 'dart:js_interop';
import 'browser_read_result.dart';

extension type BrowserStreamReader._(JSObject _) implements JSObject {
  external JSPromise<BrowserReadResult> read();
  external JSPromise<JSAny?> cancel();
  external void releaseLock();
}
