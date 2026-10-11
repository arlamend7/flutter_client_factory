/// A parsed SSE event and optional reconnect metadata.
/// An empty event name marks metadata-only parser output, filtered by the client.
class ServerSentEvent {
  const ServerSentEvent(
      {required this.data, this.event = 'message', this.id, this.retry});
  final String data;
  final String event;
  final String? id;
  final Duration? retry;
}
