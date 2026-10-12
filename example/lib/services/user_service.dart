import 'package:flutter_client_factory/flutter_client_factory.dart';
import '../models/example_user.dart';

/// Sends user requests; callers own response validation, decoding and cleanup.
class UserService {
  UserService({required HttpClient client}) : _client = client;

  final HttpClient _client;

  Future<HttpResponse> getUser(int id, {CancellationToken? cancellationToken}) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive.');
    return _client.getAsync('users/$id', cancellationToken: cancellationToken);
  }

  Future<HttpResponse> findUsers(String email,
          {CancellationToken? cancellationToken}) =>
      _client.getAsync('users',
          queryParameters: {'email': email},
          cancellationToken: cancellationToken);

  Future<HttpResponse> createUser(ExampleUser user,
          {CancellationToken? cancellationToken}) =>
      _client.postAsync('users',
          body: JsonRequestBody(user.toJson()),
          cancellationToken: cancellationToken);

  Future<HttpResponse> updateUser(ExampleUser user,
          {CancellationToken? cancellationToken}) =>
      _client.putAsync('users/${user.id}',
          body: JsonRequestBody(user.toJson()),
          cancellationToken: cancellationToken);
}
