import 'http_transport.dart';

/// Must create a new, independently owned transport for each registration.
typedef HttpTransportBuilder = HttpTransport Function();
