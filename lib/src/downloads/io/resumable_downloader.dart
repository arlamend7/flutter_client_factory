import 'dart:convert';
import 'dart:io' show File, FileMode;
import '../../core/cancellation/cancellation_token.dart';
import '../../http/contracts/http_client.dart';
import '../../http/models/http_headers.dart';
import '../../http/models/http_request.dart';

/// Uses sibling .part/.part.json files. One caller may own a destination at a time.
class ResumableDownloader {
  ResumableDownloader(this.client);
  final HttpClient client;
  Future<File> download(Uri uri, File destination,
      {CancellationToken? cancellationToken}) async {
    final token = cancellationToken ?? CancellationToken();
    final partial = File('${destination.path}.part');
    final metadata = File('${destination.path}.part.json');
    String? validator;
    var offset = 0;
    if (await partial.exists() && await metadata.exists()) {
      try {
        final Object? data = jsonDecode(await metadata.readAsString());
        if (data is Map<String, dynamic> &&
            data['url'] == uri.toString() &&
            data['etag'] is String) {
          validator = data['etag'] as String;
          offset = await partial.length();
        }
      } on FormatException {/* Invalid checkpoint starts a fresh transfer. */}
    }
    if (validator == null || validator.startsWith('W/')) offset = 0;
    var headers = HttpHeaders({
      'accept-encoding': ['identity']
    });
    if (offset > 0) {
      headers = headers
          .withValue('range', 'bytes=$offset-')
          .withValue('if-range', validator!);
    }
    var response = await client.send(HttpRequest(uri: uri, headers: headers),
        cancellationToken: token);
    if (response.statusCode == 416 && offset > 0) {
      await response.dispose();
      offset = 0;
      response = await client.send(
          HttpRequest(
              uri: uri,
              headers: HttpHeaders({
                'accept-encoding': ['identity']
              })),
          cancellationToken: token);
    }
    try {
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw StateError('Download failed: ${response.statusCode}.');
      }
      if (response.headers['content-encoding']
          .any((value) => value.toLowerCase() != 'identity')) {
        throw StateError('Resumable downloads require identity encoding.');
      }
      final etags = response.headers['etag'];
      final etag = etags.isEmpty ? null : etags.first;
      int? expectedTotal;
      if (response.statusCode == 206) {
        final ranges = response.headers['content-range'];
        final match = ranges.isEmpty
            ? null
            : RegExp(r'^bytes (\d+)-(\d+)/(\d+)$').firstMatch(ranges.first);
        if (match == null ||
            int.parse(match[1]!) != offset ||
            offset == 0 ||
            etag != validator) {
          throw StateError(
              'Server returned an inconsistent resume range or validator.');
        }
        expectedTotal = int.parse(match[3]!);
        if (int.parse(match[2]!) != expectedTotal - 1 ||
            expectedTotal <= offset) {
          throw StateError('Invalid resume length.');
        }
      } else {
        offset = 0;
        final lengths = response.headers['content-length'];
        expectedTotal = lengths.isEmpty ? null : int.tryParse(lengths.first);
      }
      await destination.parent.create(recursive: true);
      final sink = partial.openWrite(
          mode: offset > 0 ? FileMode.append : FileMode.write);
      // Flush truncation before associating a new validator with this partial file.
      await sink.flush();
      try {
        if (etag != null && !etag.startsWith('W/')) {
          await metadata.writeAsString(
              jsonEncode({'url': uri.toString(), 'etag': etag}),
              flush: true);
        } else if (await metadata.exists()) {
          await metadata.delete();
        }
        var written = offset;
        await for (final chunk in response.body) {
          token.throwIfCanceled();
          written += chunk.length;
          if (expectedTotal != null && written > expectedTotal) {
            throw StateError('Server exceeded declared download length.');
          }
          sink.add(chunk);
          await sink.flush();
        }
        token.throwIfCanceled();
        if (expectedTotal != null && written != expectedTotal) {
          throw StateError('Incomplete download.');
        }
      } finally {
        await sink.close();
      }
      final result = await partial.rename(destination.path);
      if (await metadata.exists()) await metadata.delete();
      return result;
    } finally {
      await response.dispose();
    }
  }
}
