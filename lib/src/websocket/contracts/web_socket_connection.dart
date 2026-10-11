/// An owned text/binary message connection with explicit asynchronous closure.
abstract class WebSocketConnection {
  Stream<Object> get messages;
  void send(Object message);
  Future<void> close([int? code, String? reason]);
}
