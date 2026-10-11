import 'dart:io' as io;

/// Native connection, idle, redirect, shutdown, trust and proxy configuration.
class IoTransportOptions {
  const IoTransportOptions(
      {this.connectionTimeout = const Duration(seconds: 15),
      this.idleTimeout = const Duration(seconds: 15),
      this.responseIdleTimeout = const Duration(seconds: 30),
      this.shutdownTimeout = const Duration(seconds: 30),
      this.maxConnectionsPerHost = 6,
      this.maxRedirects = 5,
      this.followRedirects = true,
      this.autoUncompress = true,
      this.securityContext,
      this.findProxy});
  final Duration connectionTimeout;
  final Duration idleTimeout;

  /// Maximum gap while consuming response chunks; null disables the idle budget.
  final Duration? responseIdleTimeout;
  final Duration shutdownTimeout;
  final int maxConnectionsPerHost;
  final int maxRedirects;

  /// Disable when authentication/cookie middleware must inspect every redirect hop.
  final bool followRedirects;
  final bool autoUncompress;

  /// Optional trust/client-certificate context; certificate validation stays enabled.
  final io.SecurityContext? securityContext;
  final String Function(Uri)? findProxy;
}
