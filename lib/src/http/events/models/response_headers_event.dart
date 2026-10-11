import 'http_event.dart';

/// A transport attempt has received its HTTP status and response headers.
class ResponseHeadersEvent extends HttpEvent {
  const ResponseHeadersEvent(super.uri, this.statusCode);
  final int statusCode;
}
