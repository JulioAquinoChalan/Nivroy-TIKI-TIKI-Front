import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../models/app_event.dart';
import '../models/exaroton_server.dart';
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
    final data = _readMapData(response);
    return AuthSession.fromJson(data);
  }

  Future<void> sendEmailVerification() async {
    await _post('/auth/send-email-verification', {});
  }

  Future<HealthStatus> getHealth() async {
    final response = await http.get(_uri('/health'));
    final apiResponse = _readApiResponse(response);
    final data = apiResponse.data;
    if (data is Map<String, dynamic>) {
      return HealthStatus.fromJson(data, backendOnline: apiResponse.success);
    }

    return HealthStatus.fromJson(
      const <String, dynamic>{},
      backendOnline: apiResponse.success,
    );
  }

  Future<List<AppEvent>> getEvents() async {
    final response = await http.get(_uri('/events'));
    final data = _readListData(response);
    return data
        .map((item) => AppEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MinecraftRule>> getRules() async {
    final response = await http.get(_uri('/rules'), headers: _authHeaders);
    final data = _readListData(response);
    return data
        .map((item) => MinecraftRule.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MinecraftRule> saveRule({
    required String eventType,
    required String trigger,
    required String command,
    required String target,
    required bool voiceEnabled,
    required String voiceMessage,
    bool enabled = true,
  }) async {
    final response = await _post('/rules', {
      'eventType': eventType,
      'trigger': trigger,
      'command': command,
      'target': target,
      'enabled': enabled,
      'voiceEnabled': voiceEnabled,
      'voiceMessage': voiceMessage,
    });

    return MinecraftRule.fromJson(response['rule'] as Map<String, dynamic>);
  }

  Future<MinecraftRule> updateRule({
    required String id,
    required String eventType,
    required String trigger,
    required String command,
    required String target,
    required bool voiceEnabled,
    required String voiceMessage,
    required bool enabled,
  }) async {
    final response = await _put('/rules/$id', {
      'eventType': eventType,
      'trigger': trigger,
      'command': command,
      'target': target,
      'enabled': enabled,
      'voiceEnabled': voiceEnabled,
      'voiceMessage': voiceMessage,
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
    _readApiResponse(response);
  }

  Future<void> connectTikTok(String username) async {
    await _post('/tiktok/connect', {'username': username});
  }

  Future<void> disconnectTikTok() async {
    await _post('/tiktok/disconnect', {});
  }

  Future<List<ExarotonServer>> getExarotonServers({
    required String token,
  }) async {
    final response = await http.get(
      _uri('/minecraft/exaroton/servers'),
      headers: {
        ..._authHeaders,
        if (token.trim().isNotEmpty) 'x-exaroton-token': token.trim(),
      },
    );
    final data =
        _readMapData(response)['servers'] as List<dynamic>? ?? const [];
    return data
        .map((item) => ExarotonServer.fromJson(item as Map<String, dynamic>))
        .where((server) => server.id.isNotEmpty)
        .toList();
  }

  Future<void> sendMinecraftCommand({
    required String provider,
    required String command,
    String? exarotonToken,
    String? serverId,
  }) async {
    await _post('/minecraft/commands', {
      'provider': provider,
      'command': command,
      if (exarotonToken != null && exarotonToken.trim().isNotEmpty)
        'exarotonToken': exarotonToken.trim(),
      if (serverId != null && serverId.trim().isNotEmpty)
        'serverId': serverId.trim(),
    });
  }

  Future<void> sendRuleOverlayTest({
    required String ruleId,
    required String command,
  }) async {
    await _post('/rules/$ruleId/test-overlay', {'command': command});
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
    return _readMapData(response);
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
    return _readMapData(response);
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
    return _readMapData(response);
  }

  ApiResponse<Object?> _readApiResponse(http.Response response) {
    final decoded = _decodeBody(response);
    final apiResponse = _normalizeApiResponse(decoded, response.statusCode);

    if (response.statusCode >= 400 || !apiResponse.success) {
      throw Exception(apiResponse.fallbackErrorMessage(response.statusCode));
    }

    return apiResponse;
  }

  Map<String, dynamic> _readMapData(http.Response response) {
    final data = _readApiResponse(response).data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  List<dynamic> _readListData(http.Response response) {
    final data = _readApiResponse(response).data;
    return data is List<dynamic> ? data : const [];
  }

  Object? _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw Exception('Backend returned invalid JSON (${response.statusCode})');
    }
  }

  ApiResponse<Object?> _normalizeApiResponse(Object? decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('success')) {
        return ApiResponse<Object?>.fromJson(decoded, (value) => value);
      }

      return _legacyMapResponse(decoded, statusCode);
    }

    if (decoded is List<dynamic>) {
      return ApiResponse<Object?>(
        success: statusCode < 400,
        message: '',
        data: decoded,
        error: null,
        meta: null,
        timestamp: '',
      );
    }

    return ApiResponse<Object?>(
      success: statusCode < 400,
      message: '',
      data: decoded,
      error: null,
      meta: null,
      timestamp: '',
    );
  }

  ApiResponse<Object?> _legacyMapResponse(
    Map<String, dynamic> decoded,
    int statusCode,
  ) {
    final hasLegacyOk = decoded.containsKey('ok');
    final success = hasLegacyOk ? decoded['ok'] == true : statusCode < 400;
    final error = decoded['error'];
    final message =
        decoded['message']?.toString() ??
        (success ? '' : error?.toString() ?? '');
    final data = Map<String, dynamic>.from(decoded)
      ..remove('ok')
      ..remove('error')
      ..remove('message');

    return ApiResponse<Object?>(
      success: success,
      message: message,
      data: success ? data : null,
      error: success
          ? null
          : ApiError(code: statusCode, detail: error?.toString() ?? message),
      meta: null,
      timestamp: '',
    );
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
