import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_event.dart';
import '../models/health_status.dart';
import '../models/minecraft_rule.dart';

class ApiService {
  ApiService(this.backendUrl);

  final String backendUrl;

  Uri _uri(String path) {
    return Uri.parse('${backendUrl.replaceAll(RegExp(r'/$'), '')}$path');
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
    final response = await http.get(_uri('/rules'));
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
    final response = await http.delete(_uri('/rules/$id'));
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
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
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
