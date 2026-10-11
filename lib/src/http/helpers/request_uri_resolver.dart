/// Resolves URI references without flattening repeated query parameters.
class RequestUriResolver {
  const RequestUriResolver();

  Uri resolve(Uri uri, Uri? baseUri) {
    if (uri.hasScheme) return _validate(uri);
    if (baseUri == null) {
      throw ArgumentError.value(uri, 'uri', 'A relative URI needs a base URI.');
    }

    return _validate(baseUri.resolveUri(uri));
  }

  Uri _validate(Uri uri) {
    final isHttp = uri.scheme == 'http' || uri.scheme == 'https';
    if (isHttp && uri.host.isNotEmpty && uri.userInfo.isEmpty) return uri;

    throw ArgumentError.value(
      uri,
      'uri',
      'Expected HTTP(S), a host, and no embedded credentials.',
    );
  }
}
