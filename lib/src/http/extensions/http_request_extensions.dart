import '../helpers/request_query_parameters.dart';
import '../models/http_request.dart';

/// Immutable request transformations that preserve body, context, and timeout.
extension HttpRequestExtensions on HttpRequest {
  HttpRequest withHeader(String name, String value) =>
      copyWith(headers: headers.withValue(name, value));

  HttpRequest withoutHeader(String name) =>
      copyWith(headers: headers.without([name]));

  /// Replaces supplied keys, preserving other keys and repeated values.
  HttpRequest withQueryParameters(Map<String, Object?> parameters) =>
      copyWith(uri: const RequestQueryParameters().apply(uri, parameters));
}
