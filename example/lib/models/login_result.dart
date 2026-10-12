import 'example_user.dart';

/// Example application contract; adapt these JSON keys to your own backend.
class LoginResult {
  const LoginResult({required this.token, required this.user});

  factory LoginResult.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Expected a login object.');
    }
    final token = json['token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Expected a non-empty token.');
    }
    return LoginResult(token: token, user: ExampleUser.fromJson(json['user']));
  }

  final String token;
  final ExampleUser user;
}
