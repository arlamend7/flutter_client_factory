import 'package:flutter_client/flutter_client.dart';
import 'package:flutter_client/testing.dart';
import 'package:test/test.dart';

void main() {
  test('matched requests remain outstanding until flushed', () async {
    final controller = HttpTestingController();
    final pending = controller.send(
        HttpRequest(uri: Uri.parse('https://example.invalid/')),
        CancellationToken());
    final request = controller.expectOne('https://example.invalid/');
    expect(controller.verify, throwsStateError);
    request.flush(HttpResponse.bytes(statusCode: 201));
    final response = await pending;
    expect(response.statusCode, 201);
    controller.verify();
    await response.dispose();
    await controller.close();
  });
}
