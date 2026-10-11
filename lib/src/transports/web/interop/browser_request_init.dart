import 'dart:js_interop';
import 'browser_headers.dart';

extension type BrowserRequestInit._(JSObject _) implements JSObject {
  external factory BrowserRequestInit(
      {String method,
      BrowserHeaders headers,
      JSUint8Array? body,
      JSObject signal,
      String credentials,
      String redirect,
      String cache,
      String mode,
      String referrerPolicy});
}
