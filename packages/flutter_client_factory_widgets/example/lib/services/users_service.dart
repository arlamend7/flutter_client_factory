import 'package:flutter_client_factory/flutter_client_factory.dart';

/// Borrows its client; callers own response validation and consumption.
class UsersService {
  UsersService({required HttpClient client}) : _client = client;
  final HttpClient _client;

  Future<HttpResponse> getUser(int id, {CancellationToken? cancellationToken}) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive.');
    return _client.getAsync('users/$id', cancellationToken: cancellationToken);
  }
}
