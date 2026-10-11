/// Base event emitted by the optional client observer for each transport attempt.
abstract class HttpEvent {
  const HttpEvent(this.uri);
  final Uri uri;
}
