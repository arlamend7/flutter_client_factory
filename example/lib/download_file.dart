import 'dart:io';
import 'package:flutter_client/downloads.dart';
import 'package:flutter_client/flutter_client.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln(
        'Usage: dart run example/lib/download_file.dart URL OUTPUT_PATH');
    exitCode = 64;
    return;
  }
  final transport = createPlatformTransport();
  final client = HttpClientService(transport: transport);
  try {
    final file = await ResumableDownloader(client)
        .download(Uri.parse(arguments[0]), File(arguments[1]));
    stdout.writeln('Completed ${file.path}: ${await file.length()} bytes');
  } finally {
    client.dispose();
    await transport.close();
  }
}
