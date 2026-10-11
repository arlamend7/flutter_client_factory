import 'dart:io';
import '../models/stored_cookie.dart';

/// Per-session host-only jar. Parent-domain cookies are intentionally rejected.
class CookieJar {
  CookieJar({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  final Map<String, StoredCookie> _cookies = {};
  void store(Uri uri, Iterable<String> values) {
    for (final value in values) {
      Cookie cookie;
      try {
        cookie = Cookie.fromSetCookieValue(value);
      } on FormatException {
        continue;
      }
      final domain =
          cookie.domain?.replaceFirst(RegExp(r'^\.'), '').toLowerCase();
      if (domain != null && domain != uri.host.toLowerCase()) continue;
      if (cookie.secure && uri.scheme != 'https') continue;
      var path = cookie.path;
      if (path == null || !path.startsWith('/')) {
        final slash = uri.path.lastIndexOf('/');
        path = slash <= 0 ? '/' : uri.path.substring(0, slash);
      }
      if (cookie.name.startsWith('__Secure-') &&
          (!cookie.secure || uri.scheme != 'https')) {
        continue;
      }
      if (cookie.name.startsWith('__Host-') &&
          (!cookie.secure || cookie.domain != null || path != '/')) {
        continue;
      }
      final key = '${uri.host}|$path|${cookie.name}';
      final expires = cookie.maxAge != null
          ? _clock().add(Duration(seconds: cookie.maxAge!))
          : cookie.expires;
      if (expires != null && !expires.isAfter(_clock())) {
        _cookies.remove(key);
        continue;
      }
      _cookies[key] = StoredCookie(
          cookie: cookie, host: uri.host, path: path, expires: expires);
    }
  }

  String header(Uri uri) {
    _cookies.removeWhere((key, value) =>
        value.expires != null && !value.expires!.isAfter(_clock()));
    final matching = _cookies.values
        .where((value) =>
            value.host == uri.host &&
            (!value.cookie.secure || uri.scheme == 'https') &&
            (uri.path == value.path ||
                uri.path.startsWith(
                    value.path.endsWith('/') ? value.path : '${value.path}/')))
        .toList()
      ..sort((a, b) => b.path.length.compareTo(a.path.length));
    return matching
        .map((value) => '${value.cookie.name}=${value.cookie.value}')
        .join('; ');
  }

  void clear() => _cookies.clear();
}
