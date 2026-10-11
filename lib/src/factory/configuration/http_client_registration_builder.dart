import 'dart:collection';

import '../../http/configuration/http_client_options.dart';
import '../../http/events/models/http_event.dart';
import '../../http/helpers/request_uri_resolver.dart';
import '../../http/middleware/contracts/http_interceptor.dart';
import '../../http/models/http_headers.dart';
import '../../transports/contracts/http_transport_builder.dart';
import '../../transports/platform/platform_transport.dart';
import '../models/client_registration.dart';

/// Mutable registration configuration, copied into an immutable snapshot by [build].
/// Does not create a transport or send requests.
class HttpClientRegistrationBuilder {
  HttpClientRegistrationBuilder({
    this.baseUrl,
    this.timeout,
    Map<String, String> defaultHeaders = const {},
    List<HttpInterceptor> interceptors = const [],
    this.transportLifetime = const Duration(minutes: 5),
    this.createTransport = createPlatformTransport,
    this.onEvent,
  }) : interceptors = List<HttpInterceptor>.of(interceptors) {
    this.defaultHeaders.addAll(defaultHeaders);
  }

  /// Absolute HTTP(S) base URL; null requires absolute request URIs.
  String? baseUrl;

  /// Optional positive overall request deadline, including body consumption.
  Duration? timeout;

  /// Mutable single-value defaults with case-insensitive header names.
  /// Use ClientRegistration with HttpHeaders for multivalue defaults.
  final Map<String, String> defaultHeaders = LinkedHashMap<String, String>(
    equals: (left, right) => left.toLowerCase() == right.toLowerCase(),
    hashCode: (name) => name.toLowerCase().hashCode,
  );

  /// Outermost-first policies; resends repeat only downstream interceptors.
  final List<HttpInterceptor> interceptors;

  /// Positive lifetime for lazily created, factory-owned transports.
  Duration transportLifetime;

  /// Each call must return an independently owned transport.
  HttpTransportBuilder createTransport;

  /// Optional observer for transport events.
  void Function(HttpEvent)? onEvent;

  /// Validates settings and copies collections without constructing a transport.
  ClientRegistration build() {
    final url = baseUrl;
    final baseUri = url == null
        ? null
        : const RequestUriResolver().resolve(Uri.parse(url), null);
    return ClientRegistration(
      createTransport: createTransport,
      transportLifetime: transportLifetime,
      options: HttpClientOptions(
        baseUri: baseUri,
        timeout: timeout,
        headers: HttpHeaders(defaultHeaders.map(
          (name, value) => MapEntry(name, [value]),
        )),
        interceptors: interceptors,
        onEvent: onEvent,
      ),
    );
  }
}
