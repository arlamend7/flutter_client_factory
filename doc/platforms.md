# Compatibility and platform limits

Minimum language/SDK target: **Dart 3.4**, below Dart 4. Flutter compatibility follows
the Dart SDK bundled with the Flutter release, not an unrestricted Flutter version
claim. No package can promise compatibility with every past and future SDK version.
Use maintained release branches if an older SDK becomes a supported requirement.

| Feature | Native Dart / Flutter | Browser JS / Wasm |
| --- | --- | --- |
| HTTP, factory, policies, cache, resources | Yes | Yes |
| Streaming response | Yes | Fetch ReadableStream |
| Streaming upload | Yes | No; known length, bounded buffer |
| TLS roots/client certificate context, proxy | SDK SecurityContext / proxy callback | Browser managed |
| Pool/socket/connect/idle tuning | SDK transport options | Browser managed |
| Cookie storage | Optional host-scoped jar | Browser managed; credentials option |
| XSRF cookie-to-header | Application middleware | Opt-in, same-origin unsafe methods |
| Redirect policy | Bounded; strip cross-origin credentials; reject HTTPS downgrade | Fetch policy; CORS restrictions |
| WebSocket | Native adapter | Browser adapter; no custom headers |
| SSE | Yes | Yes; CORS applies |
| File resumption, TCP/TLS/UDP | Native imports only | Unavailable |

The native SDK does not provide a general HTTP/2 or HTTP/3 client transport here.
Browser protocol negotiation is browser controlled. There is no TLS verification
bypass option, certificate-pinning engine, QUIC, gRPC codec, background mobile
transfer service, or connectivity-detection oracle. Add custom transports behind
`HttpTransport` when capabilities beyond the SDK are required.

Browsers may hide response headers or collapse repeated values. CORS requires server
configuration and cannot be bypassed by this library. Fetch cannot expose opaque
manual-redirect responses. Browsers restrict request headers and HTTP methods and
do not expose wire-level upload progress. Unknown-length uploads are rejected.
Mobile applications must configure their own platform network permissions.

See [validation results](validation.md) for platforms actually executed. CI support
is not evidence that every operating system/device has already been exercised.
