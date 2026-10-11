/// RFC 1123 HTTP dates without a dart:io dependency.
class HttpDateCodec {
  const HttpDateCodec();
  DateTime? parse(String value) {
    final parts = value.split(' ');
    if (parts.length != 6 || parts.last != 'GMT') return null;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months.indexOf(parts[2]) + 1;
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[3]);
    final time = parts[4].split(':').map(int.tryParse).toList();
    if (month == 0 ||
        day == null ||
        year == null ||
        time.length != 3 ||
        time.contains(null)) {
      return null;
    }
    return DateTime.utc(year, month, day, time[0]!, time[1]!, time[2]!);
  }
}
