import 'context_key.dart';

/// Immutable request options. Mutable attempt state belongs to middleware.
class RequestContext {
  RequestContext() : _values = const <Object, Object?>{};

  RequestContext._(Map<Object, Object?> values)
      : _values = Map<Object, Object?>.unmodifiable(values);

  final Map<Object, Object?> _values;

  T get<T>(ContextKey<T> key) {
    if (!_values.containsKey(key)) return key.createDefault();
    return _values[key] as T;
  }

  RequestContext withValue<T>(ContextKey<T> key, T value) {
    return RequestContext._(<Object, Object?>{..._values, key: value});
  }
}
