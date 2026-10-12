import 'package:flutter_client_factory/flutter_client_factory.dart';

/// Example contract for your backend, not a JSONPlaceholder endpoint.
class AuthenticationService {
  AuthenticationService({required HttpClient client}) : _client = client;

  final HttpClient _client;

  Future<HttpResponse> login(String email, String password,
          {CancellationToken? cancellationToken}) =>
      _client.postAsync('auth/login',
          body: JsonRequestBody({'email': email, 'password': password}),
          cancellationToken: cancellationToken);
}
