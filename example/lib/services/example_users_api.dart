import 'package:flutter_client_factory/flutter_client_factory.dart';
import '../models/example_user.dart';

/// Application service: receives a client instead of creating a factory.
class ExampleUsersApi {
  ExampleUsersApi(this._client);

  final HttpClient _client;

  /// Decode the response into a value the application understands.
  Future<ExampleUser> getById(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive.');

    final response = await _client.getAsync('users/$id');
    if (!response.isSuccessful) {
      await response.dispose();
      throw HttpStatusException(response.statusCode,
          headers: response.headers, uri: response.uri);
    }

    return response.readJson(decode: ExampleUser.fromJson);
  }

  /// Read the same endpoint as raw text, without JSON conversion.
  Future<String> getTextById(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive.');

    final response = await _client.getAsync('users/$id');
    if (!response.isSuccessful) {
      await response.dispose();
      throw HttpStatusException(response.statusCode,
          headers: response.headers, uri: response.uri);
    }

    return response.readText();
  }

  /// Dispose only if this service owns its injected logical client.
  void dispose() => _client.dispose();
}
