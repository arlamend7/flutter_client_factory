import '../../core/cancellation/cancellation_token.dart';
import '../../core/metadata/request_context.dart';
import '../bodies/request_body.dart';
import '../contracts/http_client.dart';
import '../enums/http_method.dart';
import '../helpers/request_query_parameters.dart';
import '../models/http_headers.dart';
import '../models/http_request.dart';
import '../models/http_response.dart';

/// String-URL convenience methods over the same send pipeline.
/// Raw responses retain all HTTP statuses and must be consumed or disposed.
extension HttpClientRequests on HttpClient {
  /// Sends GET. A timeout overrides the client's default overall deadline.
  Future<HttpResponse> getAsync(
    String url, {
    Map<String, Object?> queryParameters = const {},
    Map<String, String> headers = const {},
    RequestBody? body,
    RequestContext? context,
    CancellationToken? cancellationToken,
    Duration? timeout,
  }) =>
      _request(HttpMethod.get, url,
          queryParameters: queryParameters,
          headers: headers,
          body: body,
          context: context,
          cancellationToken: cancellationToken,
          timeout: timeout);

  /// Sends POST. A timeout overrides the client's default overall deadline.
  Future<HttpResponse> postAsync(
    String url, {
    Map<String, Object?> queryParameters = const {},
    Map<String, String> headers = const {},
    RequestBody? body,
    RequestContext? context,
    CancellationToken? cancellationToken,
    Duration? timeout,
  }) =>
      _request(HttpMethod.post, url,
          queryParameters: queryParameters,
          headers: headers,
          body: body,
          context: context,
          cancellationToken: cancellationToken,
          timeout: timeout);

  /// Sends PUT. A timeout overrides the client's default overall deadline.
  Future<HttpResponse> putAsync(
    String url, {
    Map<String, Object?> queryParameters = const {},
    Map<String, String> headers = const {},
    RequestBody? body,
    RequestContext? context,
    CancellationToken? cancellationToken,
    Duration? timeout,
  }) =>
      _request(HttpMethod.put, url,
          queryParameters: queryParameters,
          headers: headers,
          body: body,
          context: context,
          cancellationToken: cancellationToken,
          timeout: timeout);

  /// Sends PATCH. A timeout overrides the client's default overall deadline.
  Future<HttpResponse> patchAsync(
    String url, {
    Map<String, Object?> queryParameters = const {},
    Map<String, String> headers = const {},
    RequestBody? body,
    RequestContext? context,
    CancellationToken? cancellationToken,
    Duration? timeout,
  }) =>
      _request(HttpMethod.patch, url,
          queryParameters: queryParameters,
          headers: headers,
          body: body,
          context: context,
          cancellationToken: cancellationToken,
          timeout: timeout);

  /// Sends DELETE. A timeout overrides the client's default overall deadline.
  Future<HttpResponse> deleteAsync(
    String url, {
    Map<String, Object?> queryParameters = const {},
    Map<String, String> headers = const {},
    RequestBody? body,
    RequestContext? context,
    CancellationToken? cancellationToken,
    Duration? timeout,
  }) =>
      _request(HttpMethod.delete, url,
          queryParameters: queryParameters,
          headers: headers,
          body: body,
          context: context,
          cancellationToken: cancellationToken,
          timeout: timeout);

  /// Sends HEAD. A timeout overrides the client's default overall deadline.
  Future<HttpResponse> headAsync(
    String url, {
    Map<String, Object?> queryParameters = const {},
    Map<String, String> headers = const {},
    RequestBody? body,
    RequestContext? context,
    CancellationToken? cancellationToken,
    Duration? timeout,
  }) =>
      _request(HttpMethod.head, url,
          queryParameters: queryParameters,
          headers: headers,
          body: body,
          context: context,
          cancellationToken: cancellationToken,
          timeout: timeout);

  /// Sends OPTIONS. A timeout overrides the client's default overall deadline.
  Future<HttpResponse> optionsAsync(
    String url, {
    Map<String, Object?> queryParameters = const {},
    Map<String, String> headers = const {},
    RequestBody? body,
    RequestContext? context,
    CancellationToken? cancellationToken,
    Duration? timeout,
  }) =>
      _request(HttpMethod.options, url,
          queryParameters: queryParameters,
          headers: headers,
          body: body,
          context: context,
          cancellationToken: cancellationToken,
          timeout: timeout);

  Future<HttpResponse> _request(
    HttpMethod method,
    String url, {
    Map<String, Object?> queryParameters = const {},
    Map<String, String> headers = const {},
    RequestBody? body,
    RequestContext? context,
    CancellationToken? cancellationToken,
    Duration? timeout,
  }) =>
      send(
        HttpRequest(
          uri: const RequestQueryParameters()
              .apply(Uri.parse(url), queryParameters),
          method: method,
          headers: HttpHeaders.single(headers),
          body: body,
          context: context,
          timeout: timeout,
        ),
        cancellationToken: cancellationToken,
      );
}
