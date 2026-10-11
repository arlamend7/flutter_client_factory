import 'http_event.dart';

/// A response body was fully consumed; cancellation does not emit completion.
class ResponseCompletedEvent extends HttpEvent {
  const ResponseCompletedEvent(super.uri);
}
