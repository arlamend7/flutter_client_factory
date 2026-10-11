import 'http_event.dart';

/// Cumulative bytes handed to one transport attempt, not peer acknowledgment.
class UploadProgressEvent extends HttpEvent {
  const UploadProgressEvent(super.uri, this.transferred);
  final int transferred;
}
