import '../../http/models/http_headers.dart';

/// Replaces sensitive header values while preserving safe diagnostic headers.
class HeaderRedactor {
  HeaderRedactor(
      {Set<String> sensitiveNames = const {
        'authorization',
        'proxy-authorization',
        'cookie',
        'set-cookie'
      }})
      : _sensitive = sensitiveNames.map((name) => name.toLowerCase()).toSet();
  final Set<String> _sensitive;
  Map<String, List<String>> redact(HttpHeaders headers) =>
      headers.values.map((name, values) => MapEntry(
          name, _sensitive.contains(name) ? const ['[REDACTED]'] : values));
}
