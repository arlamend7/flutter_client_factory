import '../../http/models/buffered_http_response.dart';

/// A buffered representation, its freshness deadline and selected Vary headers.
class CacheEntry {
  CacheEntry(
      {required this.response,
      required this.expiresAt,
      required Map<String, List<String>> vary})
      : vary = Map.unmodifiable(vary.map((name, values) =>
            MapEntry(name, List<String>.unmodifiable(values))));
  final BufferedHttpResponse response;
  final DateTime expiresAt;
  final Map<String, List<String>> vary;
}
