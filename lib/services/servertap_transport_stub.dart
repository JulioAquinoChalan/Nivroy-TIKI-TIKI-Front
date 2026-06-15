import 'package:http/http.dart' as http;

class ServerTapResponse {
  const ServerTapResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

Future<ServerTapResponse> serverTapRequest(
  Uri uri, {
  required String method,
  Map<String, String>? headers,
  Map<String, String>? body,
}) async {
  final response = switch (method) {
    'POST' => await http.post(uri, headers: headers, body: body),
    _ => await http.get(uri, headers: headers),
  };

  return ServerTapResponse(
    statusCode: response.statusCode,
    body: response.body,
  );
}
