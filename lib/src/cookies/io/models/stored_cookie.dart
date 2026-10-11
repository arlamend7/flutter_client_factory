import 'dart:io';

class StoredCookie {
  StoredCookie(
      {required this.cookie,
      required this.host,
      required this.path,
      this.expires});
  final Cookie cookie;
  final String host;
  final String path;
  final DateTime? expires;
}
