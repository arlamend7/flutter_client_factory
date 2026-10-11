import 'dart:io';
import '../../bodies/stream_request_body.dart';
import '../../models/multipart_part.dart';

/// Native file uploads without buffering the whole file in memory.
extension FileMultipartExtensions on File {
  /// Creates a one-shot streaming part. Do not modify the file during upload.
  /// One-shot semantics prevent automatic retries of a changing file.
  Future<MultipartPart> asMultipartPart(
      {required String name,
      String? filename,
      String contentType = 'application/octet-stream'}) async {
    final size = await length();
    return MultipartPart(
        name: name,
        filename: filename ?? uri.pathSegments.last,
        body: StreamRequestBody(openRead(),
            contentLength: size, contentType: contentType));
  }
}
