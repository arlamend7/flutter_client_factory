/// Loading, last data and terminal error state for an explicitly refreshed resource.
class ResourceState<T> {
  const ResourceState(
      {this.data, this.error, this.stackTrace, this.isLoading = false});
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;
  final bool isLoading;
}
