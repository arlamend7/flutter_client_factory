import 'dart:js_interop';
import 'browser_stream_reader.dart';

extension type BrowserReadableStream._(JSObject _) implements JSObject {
  external BrowserStreamReader getReader();
}
