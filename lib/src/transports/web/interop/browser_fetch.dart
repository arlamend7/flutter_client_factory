import 'dart:js_interop';
import 'browser_request_init.dart';
import 'browser_response.dart';

@JS('fetch')
external JSPromise<BrowserResponse> browserFetch(
    String url, BrowserRequestInit options);
@JS('location.origin')
external String get browserOrigin;
@JS('document.cookie')
external String get browserCookies;
