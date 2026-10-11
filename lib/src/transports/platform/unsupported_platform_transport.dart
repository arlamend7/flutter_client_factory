import '../contracts/http_transport.dart';

HttpTransport createPlatformTransport() =>
    throw UnsupportedError('No HTTP transport for this runtime.');
