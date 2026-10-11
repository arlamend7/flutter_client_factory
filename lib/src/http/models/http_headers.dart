/// Immutable, case-insensitive names with separate values preserved.
class HttpHeaders {
  factory HttpHeaders([Map<String, List<String>> values = const {}]) {
    final normalized = <String, List<String>>{};

    for (final entry in values.entries) {
      final name = entry.key.toLowerCase();
      if (!RegExp(r"^[!#$%&'*+.^_`|~0-9a-z-]+$").hasMatch(name)) {
        throw ArgumentError.value(entry.key, 'header name');
      }
      if (entry.value.any((value) => RegExp(r'[\r\n\x00]').hasMatch(value))) {
        throw ArgumentError('Header values cannot contain CR, LF, or NUL.');
      }
      normalized.putIfAbsent(name, () => <String>[]).addAll(entry.value);
    }

    return HttpHeaders._(normalized);
  }

  HttpHeaders._(Map<String, List<String>> values)
      : values = Map<String, List<String>>.unmodifiable(
          values.map((name, entries) =>
              MapEntry(name, List<String>.unmodifiable(entries))),
        );

  final Map<String, List<String>> values;

  List<String> operator [](String name) =>
      values[name.toLowerCase()] ?? const <String>[];

  bool contains(String name) => values.containsKey(name.toLowerCase());

  HttpHeaders withValue(String name, String value) {
    return HttpHeaders(<String, List<String>>{
      ...values,
      name.toLowerCase(): <String>[value],
    });
  }

  HttpHeaders without(Iterable<String> names) {
    final excluded = names.map((name) => name.toLowerCase()).toSet();
    return HttpHeaders(Map.fromEntries(
        values.entries.where((entry) => !excluded.contains(entry.key))));
  }

  /// Values from [overrides] replace values with the same name.
  HttpHeaders merge(HttpHeaders overrides) {
    return HttpHeaders(<String, List<String>>{...values, ...overrides.values});
  }
}
