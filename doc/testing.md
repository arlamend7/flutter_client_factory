# Testing applications and policies

Import the core and `testing.dart`. The helpers themselves have no dependency on a
test framework; use `package:test` or Flutter's test package in your application.

## Small service tests

```dart
final controller = HttpTestingController();
final client = controller.createClient(baseUrl: 'https://test.invalid/');
addTearDown(() async {
  try {
    controller.verify();
  } finally {
    client.dispose();
    await controller.close();
  }
});

final pending = client.getAsync('users');
final request = await controller.waitForOne(
  'https://test.invalid/users', method: HttpMethod.get);
request.flushJson([{'name': 'Ada'}]);
final response = await pending;
expect(await response.readJson(decode: (json) => json), [{'name': 'Ada'}]);
```

For a real service test, invoke `UsersApi(client).getById(...)` instead of a raw
request. Match the resulting request and complete it in the same way. Configure
the same interceptors as production; replace the transport rather than mocking
away the whole client pipeline.

## What to exercise

| Behavior | How to simulate it | What to assert |
| --- | --- | --- |
| Success | flushJson/flushText | Domain data and request method/URL/headers |
| HTTP failure | flush with 400/401/500 status | Application status policy and response cleanup |
| Network failure | fail with a NetworkException | Error mapping and eligible retry limits |
| Invalid data | flushText with malformed JSON | Decoder failure without leaked response |
| Cancellation | cancel the caller token | Pending request fails; unrelated work continues |
| Deadline | short timeout with a pending request or stalled body | RequestTimeoutException and token cancellation |
| Retry | fail/flush 503, then wait for the next request | Downstream policies repeat and failed response is disposed |
| Auth refresh | 401 then success with new credentials | One refresh and correct allowed-origin handling |
| Duplicate work | match predicate for a batch | Exact count and every request completed |
| Cache | repeated reads, Vary, 304, credentialed requests | Correct hit/miss and session isolation |

Use `waitForOne` for asynchronous middleware such as token loading; avoid arbitrary
sleeps. It defaults to a bounded five-second wait, reports outstanding requests,
and releases its timer/subscription. `expectOne` is for requests already captured.
Both match full URLs including query strings; add method or use a predicate for
custom matching. Duplicate expectations do not consume the candidates.

Always await request work and verify before closing the controller. Matching alone
does not complete a request. `ignoreCanceled: true` is appropriate only when the test
intentionally canceled those requests. Fakes verify application behavior; actual
transport abortion, CORS, TLS, pooling and socket behavior require integration tests.

## Library validation

Follow [release checks](releasing.md) for the full suite and minimum-SDK isolation.
The browser harness tests JS and Wasm against local fixtures. Flutter tests live in
the adapter package. Tests do not prove every OS/device or timing schedule; see the
[validation record](validation.md) for the environments actually exercised.
