/// Fetch credentials, redirect, upload limit and same-origin XSRF options.
class WebTransportOptions {
  WebTransportOptions(
      {this.credentials = 'same-origin',
      this.redirect = 'follow',
      this.cache = 'default',
      this.referrerPolicy = 'strict-origin-when-cross-origin',
      this.maxUploadBytes = 8 * 1024 * 1024,
      this.xsrfCookieName,
      this.xsrfHeaderName = 'x-xsrf-token'}) {
    if (!{'omit', 'same-origin', 'include'}.contains(credentials) ||
        !{'follow', 'error', 'manual'}.contains(redirect) ||
        maxUploadBytes < 0) {
      throw ArgumentError('Invalid browser transport options.');
    }
  }
  final String credentials;
  final String redirect;
  final String cache;
  final String referrerPolicy;

  /// Maximum known-length upload buffered before calling Fetch.
  final int maxUploadBytes;

  /// Opt-in cookie to copy to [xsrfHeaderName] for same-origin unsafe methods.
  final String? xsrfCookieName;
  final String xsrfHeaderName;
}
