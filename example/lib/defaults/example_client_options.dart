import 'package:flutter_client/flutter_client.dart';

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
