import '../../core/cancellation/cancellation_token.dart';
import '../../core/errors/network_exception.dart';
import '../../http/contracts/http_client.dart';
import '../../http/models/http_headers.dart';
import '../../http/models/http_request.dart';
import '../models/server_sent_event.dart';
import 'server_sent_event_parser.dart';

/// Consumes HTTP event streams with bounded reconnects and last-event IDs.
/// Supply and cancel a token to release a connection whose stream is stalled.
class ServerSentEventsClient {
  ServerSentEventsClient(this.client,
      {this.maxReconnects = 3,
      this.reconnectDelay = const Duration(seconds: 1)}) {
    if (maxReconnects < 0 || reconnectDelay < Duration.zero) {
      throw ArgumentError('Invalid SSE reconnect budget.');
    }
  }
  final HttpClient client;
  final int maxReconnects;
  final Duration reconnectDelay;
  Stream<ServerSentEvent> connect(Uri uri,
      {CancellationToken? cancellationToken}) async* {
    final token = cancellationToken ?? CancellationToken();
    var delay = reconnectDelay;
    var lastId = '';
    for (var attempt = 0;; attempt++) {
      token.throwIfCanceled();
      var headers = HttpHeaders({
        'accept': ['text/event-stream'],
        'cache-control': ['no-cache']
      });
      if (lastId.isNotEmpty) {
        headers = headers.withValue('last-event-id', lastId);
      }
      try {
        final response = await client.send(
            HttpRequest(uri: uri, headers: headers),
            cancellationToken: token);
        try {
          if (response.statusCode == 204) return;
          if (response.statusCode != 200 ||
              !response.headers['content-type'].any((value) =>
                  value.split(';').first.trim().toLowerCase() ==
                  'text/event-stream')) {
            throw StateError('Expected a 200 text/event-stream response.');
          }
          await for (final event
              in ServerSentEventParser().parse(response.body)) {
            if (event.id != null) lastId = event.id!;
            if (event.retry != null) {
              delay = Duration(
                  milliseconds: event.retry!.inMilliseconds.clamp(0, 30000));
            }
            if (event.event.isNotEmpty) yield event;
          }
        } finally {
          await response.dispose();
        }
      } on NetworkException {
        if (attempt >= maxReconnects) rethrow;
      }
      if (attempt >= maxReconnects) return;
      await token.wait(delay);
    }
  }
}
