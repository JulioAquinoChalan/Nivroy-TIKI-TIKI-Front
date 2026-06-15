import 'dart:async';

import 'package:http/http.dart' as http;

const _serverTapRequestTimeout = Duration(seconds: 8);

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
  final request = switch (method) {
    'POST' => http.post(uri, headers: headers, body: body),
    _ => http.get(uri, headers: headers),
  };

  final response = await request.timeout(
    _serverTapRequestTimeout,
    onTimeout: () => throw TimeoutException(
      'ServerTap no respondio. Revisa la URL/IP y vuelve a intentar.',
      _serverTapRequestTimeout,
    ),
  );

  return ServerTapResponse(
    statusCode: response.statusCode,
    body: response.body,
  );
}
