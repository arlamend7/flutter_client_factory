import 'http_event.dart';

/// A transport attempt is about to start.
class RequestSentEvent extends HttpEvent {
  const RequestSentEvent(super.uri);
}
