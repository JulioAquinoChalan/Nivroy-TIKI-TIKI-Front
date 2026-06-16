import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

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
  final requestHeaders = web.Headers();
  for (final entry in (headers ?? const <String, String>{}).entries) {
    requestHeaders.set(entry.key, entry.value);
  }

  final response = await web.window
      .fetch(
        uri.toString().toJS,
        web.RequestInit(
          method: method,
          headers: requestHeaders,
          body: body == null ? null : _encodeFormBody(body).toJS,
          mode: 'cors',
          targetAddressSpace: _targetAddressSpace(uri),
        ),
      )
      .toDart
      .timeout(
        _serverTapRequestTimeout,
        onTimeout: () => throw TimeoutException(
          'ServerTap no respondio. Revisa la URL/IP y vuelve a intentar.',
          _serverTapRequestTimeout,
        ),
      );

  return ServerTapResponse(
    statusCode: response.status,
    body: (await response.text().toDart).toDart,
  );
}

String _targetAddressSpace(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '::1' ||
      host.startsWith('10.') ||
      host.startsWith('192.168.') ||
      _isPrivate172Address(host)) {
    return 'local';
  }

  return 'unknown';
}

bool _isPrivate172Address(String host) {
  final parts = host.split('.');
  if (parts.length != 4 || parts.first != '172') {
    return false;
  }

  final second = int.tryParse(parts[1]);
  return second != null && second >= 16 && second <= 31;
}

String _encodeFormBody(Map<String, String> body) {
  return body.entries
      .map(
        (entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
      )
      .join('&');
}
