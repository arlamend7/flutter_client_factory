/// An identity-based key for metadata that is never sent over the network.
///
/// Reuse a key instance. The factory is invoked when a context has no value.
class ContextKey<T> {
  ContextKey(this.createDefault);

  final T Function() createDefault;
}
