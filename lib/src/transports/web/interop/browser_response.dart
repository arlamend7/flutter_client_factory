import 'dart:js_interop';
import 'browser_headers.dart';
import 'browser_readable_stream.dart';

extension type BrowserResponse._(JSObject _) implements JSObject {
  external int get status;
  external String get url;
  external BrowserHeaders get headers;
  external BrowserReadableStream? get body;
}
