import 'package:flutter_client_factory/flutter_client_factory.dart';

class ExampleClientOptions {
  ExampleClientOptions._();

  static HttpClientOptions create() {
    return HttpClientOptions(
      baseUri: Uri.parse('https://example.invalid/api/'),
      headers: HttpHeaders(<String, List<String>>{
        'accept': <String>['application/json'],
      }),
    );
  }
}
