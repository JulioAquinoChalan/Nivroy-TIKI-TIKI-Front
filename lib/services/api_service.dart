import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_event.dart';
import '../models/health_status.dart';
import '../models/minecraft_rule.dart';

class ApiService {
  ApiService(this.backendUrl, {this.idToken});

  final String backendUrl;
  final String? idToken;

  Uri _uri(String path) {
    return Uri.parse('${backendUrl.replaceAll(RegExp(r'/$'), '')}$path');
  }

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    if (idToken != null && idToken!.isNotEmpty)
      'Authorization': 'Bearer $idToken',
  };

  Map<String, String> get _authHeaders => {
    if (idToken != null && idToken!.isNotEmpty)
      'Authorization': 'Bearer $idToken',
  };

  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/register', {
      'email': email,
      'password': password,
    }, includeAuth: false);
    return AuthSession.fromJson(response);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/login', {
      'email': email,
      'password': password,
    }, includeAuth: false);
    return AuthSession.fromJson(response);
  }

  Future<AuthSession> refreshAuth(String refreshToken) async {
    final response = await _post('/auth/refresh', {
      'refreshToken': refreshToken,
    }, includeAuth: false);
    return AuthSession.fromJson(response);
  }

  Future<AuthSession> getCurrentUser() async {
    final response = await http.get(_uri('/auth/me'), headers: _authHeaders);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode >= 400) {
      final message = decoded is Map<String, dynamic> ? decoded['error'] : null;
      throw Exception(message ?? 'Backend returned ${response.statusCode}');
    }

    return AuthSession.fromJson(decoded as Map<String, dynamic>);
  }

  Future<void> sendEmailVerification() async {
    await _post('/auth/send-email-verification', {});
  }

  Future<HealthStatus> getHealth() async {
    final response = await http.get(_uri('/health'));
    if (response.statusCode >= 400) {
      throw Exception('Backend returned ${response.statusCode}');
    }

    return HealthStatus.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<AppEvent>> getEvents() async {
    final response = await http.get(_uri('/events'));
    if (response.statusCode >= 400) {
      throw Exception('Backend returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => AppEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MinecraftRule>> getRules() async {
    final response = await http.get(_uri('/rules'), headers: _authHeaders);
    if (response.statusCode >= 400) {
      throw Exception('Backend returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => MinecraftRule.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MinecraftRule> saveRule({
    required String eventType,
    required String trigger,
    required String command,
    required String target,
    bool enabled = true,
  }) async {
    final response = await _post('/rules', {
      'eventType': eventType,
      'trigger': trigger,
      'command': command,
      'target': target,
      'enabled': enabled,
    });

    return MinecraftRule.fromJson(response['rule'] as Map<String, dynamic>);
  }

  Future<MinecraftRule> updateRule({
    required String id,
    required String eventType,
    required String trigger,
    required String command,
    required String target,
    required bool enabled,
  }) async {
    final response = await _put('/rules/$id', {
      'eventType': eventType,
      'trigger': trigger,
      'command': command,
      'target': target,
      'enabled': enabled,
    });

    return MinecraftRule.fromJson(response['rule'] as Map<String, dynamic>);
  }

  Future<MinecraftRule> setRuleEnabled({
    required String id,
    required bool enabled,
  }) async {
    final response = await _patch('/rules/$id/enabled', {'enabled': enabled});
    return MinecraftRule.fromJson(response['rule'] as Map<String, dynamic>);
  }

  Future<void> deleteRule(String id) async {
    final response = await http.delete(
      _uri('/rules/$id'),
      headers: _authHeaders,
    );
    if (response.statusCode >= 400) {
      throw Exception('Backend returned ${response.statusCode}');
    }
  }

  Future<void> connectTikTok(String username) async {
    await _post('/tiktok/connect', {'username': username});
  }

  Future<void> disconnectTikTok() async {
    await _post('/tiktok/disconnect', {});
  }

  Future<void> connectMinecraft({
    required String minecraftHost,
    required int minecraftPort,
  }) async {
    await _post('/minecraft/connect', {
      'minecraftHost': minecraftHost,
      'minecraftPort': minecraftPort,
    });
  }

  Future<void> executeMinecraftCommand(
    String command, {
    String username = 'dashboard',
    required String minecraftHost,
    required int minecraftPort,
  }) async {
    await _post('/minecraft/command', {
      'command': command,
      'username': username,
      'minecraftHost': minecraftHost,
      'minecraftPort': minecraftPort,
    });
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: includeAuth
          ? _jsonHeaders
          : {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode >= 400) {
      final message = decoded is Map<String, dynamic> ? decoded['error'] : null;
      throw Exception(message ?? 'Backend returned ${response.statusCode}');
    }

    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      _uri(path),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode >= 400) {
      final message = decoded is Map<String, dynamic> ? decoded['error'] : null;
      throw Exception(message ?? 'Backend returned ${response.statusCode}');
    }

    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      _uri(path),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode >= 400) {
      final message = decoded is Map<String, dynamic> ? decoded['error'] : null;
      throw Exception(message ?? 'Backend returned ${response.statusCode}');
    }

    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}

class AuthSession {
  const AuthSession({
    required this.idToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.uid,
    required this.email,
    required this.emailVerified,
  });

  final String idToken;
  final String refreshToken;
  final int expiresIn;
  final String uid;
  final String email;
  final bool emailVerified;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      idToken: json['idToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresIn: int.tryParse(json['expiresIn']?.toString() ?? '') ?? 3600,
      uid: json['uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      emailVerified: json['emailVerified'] == true,
    );
  }
}
