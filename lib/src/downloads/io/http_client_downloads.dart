import 'dart:io' show File;
import '../../core/cancellation/cancellation_token.dart';
import '../../http/contracts/http_client.dart';
import '../../http/helpers/request_uri_resolver.dart';
import 'resumable_downloader.dart';

/// Native resumable downloads over the existing client pipeline.
extension HttpClientDownloads on HttpClient {
  /// Use an absolute URL so saved resume checkpoints identify the remote resource.
  Future<File> downloadFile(String url, File destination,
          {CancellationToken? cancellationToken}) =>
      ResumableDownloader(this).download(
          const RequestUriResolver().resolve(Uri.parse(url), null), destination,
          cancellationToken: cancellationToken);
}
