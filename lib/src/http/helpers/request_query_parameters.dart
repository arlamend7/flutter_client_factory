/// Merges query parameters without flattening repeated values.
class RequestQueryParameters {
  const RequestQueryParameters();

  /// Values accept strings, numbers, booleans, or lists of strings.
  /// Supplied keys replace existing values; null or an empty list removes a key.
  Uri apply(Uri uri, Map<String, Object?> parameters) {
    if (parameters.isEmpty) return uri;
    final values = Map<String, List<String>>.of(uri.queryParametersAll);
    for (final entry in parameters.entries) {
      final value = entry.value;
      if (value == null) {
        values.remove(entry.key);
        continue;
      }
      if (value is Iterable<String>) {
        final items = value.toList();
        if (items.isEmpty) {
          values.remove(entry.key);
        } else {
          values[entry.key] = items;
        }
        continue;
      }
      if (value is! String && value is! num && value is! bool) {
        throw ArgumentError.value(value, entry.key, 'Unsupported query value');
      }
      values[entry.key] = [value.toString()];
    }
    return uri.replace(queryParameters: values);
  }
}
