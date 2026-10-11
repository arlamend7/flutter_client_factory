import 'package:flutter_client_factory/flutter_client_factory.dart';
import '../models/example_user.dart';

class ExampleUsersApi {
  ExampleUsersApi(this._client);

  final HttpClient _client;

  Future<ExampleUser> getById(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive.');

    final response = await _client.getAsync('users/$id');
    await response.requireSuccess();
    return response.readJson(decode: ExampleUser.fromJson);
  }

  void dispose() => _client.dispose();
}
