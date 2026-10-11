/// Shared protocol defaults, not example application configuration.
class HttpDefaults {
  HttpDefaults._();

  static const String jsonContentType = 'application/json; charset=utf-8';
  static const String textContentType = 'text/plain; charset=utf-8';
  static const String binaryContentType = 'application/octet-stream';
  static const int minimumSuccessStatus = 200;
  static const int maximumSuccessStatus = 299;
}
