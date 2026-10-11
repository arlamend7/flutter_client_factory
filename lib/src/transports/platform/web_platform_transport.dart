import '../contracts/http_transport.dart';
import '../web/services/web_http_transport.dart';

HttpTransport createPlatformTransport() => WebHttpTransport();
