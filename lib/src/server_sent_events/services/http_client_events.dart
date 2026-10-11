import '../../core/cancellation/cancellation_token.dart';
import '../../http/contracts/http_client.dart';
import '../models/server_sent_event.dart';
import 'server_sent_events_client.dart';

/// Optional SSE conveniences that retain explicit cancellation and reconnect limits.
extension HttpClientEvents on HttpClient {
  /// Relative URLs use the client base URL. Cancel the token to abort stalled I/O.
  Stream<ServerSentEvent> serverSentEvents(
    String url, {
    CancellationToken? cancellationToken,
    int maxReconnects = 3,
    Duration reconnectDelay = const Duration(seconds: 1),
  }) =>
      ServerSentEventsClient(this,
              maxReconnects: maxReconnects, reconnectDelay: reconnectDelay)
          .connect(Uri.parse(url), cancellationToken: cancellationToken);
}
