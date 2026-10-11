/// Bounded reconnect and application-level ping/pong configuration.
class WebSocketOptions {
  const WebSocketOptions(
      {this.maxReconnects = 3,
      this.reconnectDelay = const Duration(seconds: 1),
      this.heartbeatInterval,
      this.heartbeatTimeout = const Duration(seconds: 30),
      this.ping = 'ping',
      this.pong = 'pong'});
  final int maxReconnects;
  final Duration reconnectDelay;
  final Duration? heartbeatInterval;
  final Duration heartbeatTimeout;
  final String ping;
  final String pong;
}
