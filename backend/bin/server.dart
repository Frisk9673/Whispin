import 'dart:convert';
import 'dart:io';
import 'package:backend/services/user_service.dart';


void main() async {
  final userService = UserService();
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print('Server running on http://localhost:8080');

  await for (HttpRequest request in server) {
    if (request.method == 'POST' && request.uri.path == '/createUser') {
      try {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content);

        final success = await userService.createUser(
          email: data['email'],
          firstName: data['firstName'],
          lastName: data['lastName'],
          nickname: data['nickname'],
        );

        request.response
          ..statusCode = success ? 200 : 400
          ..write(success ? 'Success' : 'Failed');
      } catch (e) {
        request.response
          ..statusCode = 500
          ..write('Error: $e');
      } finally {
        await request.response.close();
      }
    } else {
      request.response
        ..statusCode = 404
        ..write('Not Found')
        ..close();
    }
  }
}
