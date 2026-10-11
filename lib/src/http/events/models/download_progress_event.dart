import 'http_event.dart';

/// Cumulative response bytes delivered during one transport attempt.
class DownloadProgressEvent extends HttpEvent {
  const DownloadProgressEvent(super.uri, this.transferred);
  final int transferred;
}
