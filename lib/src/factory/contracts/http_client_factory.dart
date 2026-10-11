import '../../http/contracts/http_client.dart';
import '../models/client_registration.dart';

abstract class HttpClientFactory {
  void register(String name, ClientRegistration registration);
  HttpClient create(String name);
  T createTyped<T>(String name, T Function(HttpClient client) build);
  Future<void> close();
}
