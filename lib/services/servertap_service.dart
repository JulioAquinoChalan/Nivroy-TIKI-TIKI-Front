import 'dart:convert';

import 'package:http/http.dart' as http;

import 'servertap_cookie_stub.dart'
    if (dart.library.html) 'servertap_cookie_web.dart';

class ServerTapService {
  ServerTapService({required this.baseUrl, this.key});

  final String baseUrl;
  final String? key;

  Uri _uri(String path) {
    return Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}$path');
  }

  Map<String, String> get _headers => {
    if (key != null && key!.isNotEmpty) 'key': key!,
  };

  Map<String, String> get _formHeaders => {
    ..._headers,
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  Future<Map<String, dynamic>> getServer() async {
    setServerTapCookie(key ?? '');
    final response = await http.get(_uri('/v1/server'), headers: _headers);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response.statusCode));
    }

    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Future<void> runCommand(String command) async {
    final commands = command
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (commands.isEmpty) {
      return;
    }

    for (final line in commands) {
      final response = await http.post(
        _uri('/v1/server/exec'),
        headers: _formHeaders,
        body: {'command': line, 'time': '0'},
      );

      if (response.statusCode >= 400) {
        throw Exception(_errorMessage(response.statusCode));
      }
    }
  }

  String _errorMessage(int statusCode) {
    if (statusCode == 401) {
      return 'ServerTap rechazo la conexion. Revisa SERVERTAP_KEY o desactiva useKeyAuth en plugins/ServerTap/config.yml.';
    }

    return 'ServerTap returned $statusCode';
  }
}
