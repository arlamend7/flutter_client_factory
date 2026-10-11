import '../../http/events/models/http_event.dart';
import '../../http/middleware/contracts/http_interceptor.dart';
import '../../transports/contracts/http_transport_builder.dart';
import '../../transports/platform/platform_transport.dart';
import '../configuration/http_client_registration_builder.dart';
import '../contracts/http_client_factory.dart';

/// Convenience registration for any implementation of HttpClientFactory.
extension HttpClientFactoryRegistration on HttpClientFactory {
  /// Registers a client with platform transport defaults and optional customization.
  ///
  /// Named arguments initialize a fresh builder. [configure] runs synchronously
  /// once during this call, before validation and registration, and can override
  /// those settings. Adding interceptors in the callback appends to the supplied
  /// list; clear it first to replace it. The resulting configuration is a snapshot.
  /// Callback or validation failures do not register a partially configured client.
  void registerClient(
    String name, {
    String? baseUrl,
    Duration? timeout,
    Map<String, String> defaultHeaders = const {},
    List<HttpInterceptor> interceptors = const [],
    Duration transportLifetime = const Duration(minutes: 5),
    HttpTransportBuilder createTransport = createPlatformTransport,
    void Function(HttpEvent)? onEvent,
    void Function(HttpClientRegistrationBuilder client)? configure,
  }) {
    final builder = HttpClientRegistrationBuilder(
      baseUrl: baseUrl,
      timeout: timeout,
      defaultHeaders: defaultHeaders,
      interceptors: interceptors,
      transportLifetime: transportLifetime,
      createTransport: createTransport,
      onEvent: onEvent,
    );
    configure?.call(builder);
    register(name, builder.build());
  }
}
