import '../contracts/http_transport.dart';
import '../io/services/io_http_transport.dart';

HttpTransport createPlatformTransport() => IoHttpTransport();
