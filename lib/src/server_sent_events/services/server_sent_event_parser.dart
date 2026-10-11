import 'dart:convert';
import '../models/server_sent_event.dart';

/// Parses fragmented UTF-8 event streams, multiline data and reconnect metadata.
class ServerSentEventParser {
  Stream<ServerSentEvent> parse(Stream<List<int>> bytes) async* {
    var data = <String>[];
    var event = 'message';
    String? id;
    Duration? retry;
    var first = true;
    await for (var line
        in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
      if (first) {
        line = line.replaceFirst(RegExp('^\uFEFF'), '');
        first = false;
      }
      if (line.isEmpty) {
        if (data.isNotEmpty || id != null || retry != null) {
          yield ServerSentEvent(
              data: data.join('\n'),
              event: data.isEmpty ? '' : event,
              id: id,
              retry: retry);
        }
        data = [];
        event = 'message';
        id = null;
        retry = null;
        continue;
      }
      if (line.startsWith(':')) continue;
      final colon = line.indexOf(':');
      final field = colon < 0 ? line : line.substring(0, colon);
      var value = colon < 0 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      switch (field) {
        case 'data':
          data.add(value);
        case 'event':
          event = value.isEmpty ? 'message' : value;
        case 'id':
          if (!value.contains('\u0000')) id = value;
        case 'retry':
          if (RegExp(r'^\d+$').hasMatch(value)) {
            retry = Duration(milliseconds: int.parse(value));
          }
      }
    }
    // Incomplete events at EOF are discarded, as required by the event-stream format.
  }
}
