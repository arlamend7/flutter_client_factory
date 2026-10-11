import 'package:flutter_client/flutter_client.dart';
import '../models/example_user.dart';

class ExampleUsersApi {
  ExampleUsersApi(this._client);

  final HttpClient _client;
  final ResponseBodyReader _reader = const ResponseBodyReader();

  Future<ExampleUser> getById(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive.');

    final response = await _client.send(
      HttpRequest(uri: Uri.parse('users/$id')),
    );

    if (!response.isSuccessful) {
      await response.dispose();
      throw StateError(
          'User request failed with status ${response.statusCode}.');
    }

    return _reader.readJson(response, ExampleUser.fromJson);
  }

  void dispose() => _client.dispose();
}
