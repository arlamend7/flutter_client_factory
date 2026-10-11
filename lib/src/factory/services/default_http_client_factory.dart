import '../../http/contracts/http_client.dart';
import '../../http/services/http_client_service.dart';
import '../../transports/services/delegating_http_transport.dart';
import '../contracts/http_client_factory.dart';
import '../lifecycle/models/transport_lease.dart';
import '../models/client_registration.dart';

/// Creates lightweight named clients over rotating, response-aware transport leases.
/// Owns all transports built by registrations; close the factory at scope end.
class DefaultHttpClientFactory implements HttpClientFactory {
  /// Creates a scope with a bounded grace period for active response leases.
  DefaultHttpClientFactory(
      {DateTime Function()? clock,
      this.shutdownGrace = const Duration(seconds: 30)})
      : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;

  /// Maximum lease-draining wait before invoking each transport's shutdown.
  final Duration shutdownGrace;
  final Map<String, ClientRegistration> _registrations = {};
  final Map<String, TransportLease> _leases = {};
  final List<Future<void>> _retiring = [];
  final List<Object> _retirementErrors = [];
  Future<void>? _closing;
  @override
  void register(String name, ClientRegistration registration) {
    _ensureOpen();
    if (name.trim().isEmpty) throw ArgumentError.value(name, 'name');
    if (_registrations.containsKey(name)) {
      throw StateError('Client "$name" is already registered.');
    }
    _registrations[name] = registration;
  }

  /// New clients see new options; existing clients retain their options snapshot.
  /// All subsequent dispatches use the replacement registration's transport.
  void replace(String name, ClientRegistration registration) {
    _ensureOpen();
    if (!_registrations.containsKey(name)) {
      throw StateError('Unknown client "$name".');
    }
    _registrations[name] = registration;
    final previous = _leases.remove(name);
    if (previous != null) _retire(previous);
  }

  @override
  HttpClient create(String name) {
    _ensureOpen();
    final registration = _registrations[name];
    if (registration == null) {
      throw StateError('Client "$name" is not registered.');
    }
    return HttpClientService(
        transport: DelegatingHttpTransport(
            (request, token) => _lease(name).send(request, token)),
        options: registration.options,
        isTransportAvailable: () => _closing == null);
  }

  TransportLease _lease(String name) {
    _ensureOpen();
    final registration = _registrations[name]!;
    final current = _leases[name];
    if (current != null &&
        _clock().difference(current.createdAt) <
            registration.transportLifetime) {
      return current;
    }
    final replacement =
        TransportLease(registration.createTransport(), _clock());
    _leases[name] = replacement;
    if (current != null) _retire(current);
    return replacement;
  }

  void _retire(TransportLease lease) {
    late final Future<void> task;
    task = lease.retire(shutdownGrace).catchError((Object error) {
      _retirementErrors.add(error);
    }).whenComplete(() => _retiring.remove(task));
    _retiring.add(task);
  }

  @override
  T createTyped<T>(String name, T Function(HttpClient client) build) =>
      build(create(name));
  @override
  Future<void> close() => _closing ??= Future<void>.microtask(() async {
        for (final lease in _leases.values) {
          _retire(lease);
        }
        _leases.clear();
        _registrations.clear();
        await Future.wait(_retiring.toList());
        if (_retirementErrors.isNotEmpty) throw _retirementErrors.first;
      });
  void _ensureOpen() {
    if (_closing != null) throw StateError('Factory closed.');
  }
}
