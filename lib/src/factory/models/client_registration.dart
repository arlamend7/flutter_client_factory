import '../../http/configuration/http_client_options.dart';
import '../../transports/contracts/http_transport_builder.dart';

/// An options snapshot and builder for independently owned shared transports.
class ClientRegistration {
  ClientRegistration(
      {required this.createTransport,
      HttpClientOptions? options,
      this.transportLifetime = const Duration(minutes: 5)})
      : options = options ?? HttpClientOptions() {
    if (transportLifetime <= Duration.zero) {
      throw ArgumentError.value(transportLifetime);
    }
  }
  final HttpTransportBuilder createTransport;
  final HttpClientOptions options;
  final Duration transportLifetime;
}
