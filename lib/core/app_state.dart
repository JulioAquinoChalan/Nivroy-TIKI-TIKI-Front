import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_event.dart';
import '../models/health_status.dart';
import '../models/minecraft_rule.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class AppState extends ChangeNotifier {
  static const _backendUrlKey = 'backend_url';
  static const _tiktokUsernameKey = 'tiktok_username';
  static const _minecraftHostKey = 'minecraft_host';
  static const _minecraftPortKey = 'minecraft_port';

  final WebSocketService _webSocketService = WebSocketService();

  String backendUrl = 'http://localhost:3000';
  String tiktokUsername = '';
  String minecraftHost = '127.0.0.1';
  int minecraftPort = 25575;
  String? lastError;
  bool isBusy = false;
  bool isAutoConnectingTikTok = false;
  bool isAutoConnectingMinecraft = false;
  bool websocketConnected = false;
  HealthStatus health = HealthStatus.offline();
  List<AppEvent> events = [];
  List<MinecraftRule> rules = [];

  ApiService get _api => ApiService(backendUrl);
  String get overlayRulesUrl =>
      '${backendUrl.replaceAll(RegExp(r'/$'), '')}/overlay/rules';
  String get overlayLiveStudioUrl {
    final uri = Uri.tryParse(backendUrl);
    if (uri == null) {
      return overlayRulesUrl;
    }

    final host = uri.host == 'localhost' ? '127.0.0.1' : uri.host;
    return uri
        .replace(host: host, path: '/overlay/rules', query: '')
        .toString();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    backendUrl = prefs.getString(_backendUrlKey) ?? backendUrl;
    tiktokUsername = prefs.getString(_tiktokUsernameKey) ?? '';
    minecraftHost = prefs.getString(_minecraftHostKey) ?? minecraftHost;
    minecraftPort = prefs.getInt(_minecraftPortKey) ?? minecraftPort;
    await refresh();
    connectWebSocket();
    await _autoConnectTikTok();
    await _autoConnectMinecraft();
  }

  Future<void> refresh({bool clearErrorOnSuccess = true}) async {
    try {
      health = await _api.getHealth();
      events = await _api.getEvents();
      rules = await _api.getRules();
      if (clearErrorOnSuccess) {
        lastError = null;
      }
    } catch (error) {
      health = HealthStatus.offline();
      lastError = error.toString();
    }
    notifyListeners();
  }

  Future<void> saveSettings({
    required String newBackendUrl,
    required String newTikTokUsername,
    required String newMinecraftHost,
    required String newMinecraftPort,
  }) async {
    backendUrl = newBackendUrl.trim().isEmpty
        ? backendUrl
        : newBackendUrl.trim();
    tiktokUsername = _normalizeTikTokUsername(newTikTokUsername);
    _setMinecraftConnection(newMinecraftHost, newMinecraftPort);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendUrlKey, backendUrl);
    await prefs.setString(_tiktokUsernameKey, tiktokUsername);
    await prefs.setString(_minecraftHostKey, minecraftHost);
    await prefs.setInt(_minecraftPortKey, minecraftPort);

    connectWebSocket();
    await refresh();
  }

  Future<void> saveTikTokUsername(String username) async {
    tiktokUsername = _normalizeTikTokUsername(username);
    lastError = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tiktokUsernameKey, tiktokUsername);

    notifyListeners();
  }

  Future<void> saveMinecraftConnection({
    required String host,
    required String port,
  }) async {
    _setMinecraftConnection(host, port);
    lastError = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_minecraftHostKey, minecraftHost);
    await prefs.setInt(_minecraftPortKey, minecraftPort);

    notifyListeners();
  }

  void connectWebSocket() {
    try {
      _webSocketService.connect(
        backendUrl,
        onEvent: _handleEvent,
        onError: (error) {
          websocketConnected = false;
          lastError = error.toString();
          notifyListeners();
        },
      );
      websocketConnected = true;
      lastError = null;
    } catch (error) {
      websocketConnected = false;
      lastError = error.toString();
    }
    notifyListeners();
  }

  Future<void> connectTikTok({String? username}) async {
    if (username != null) {
      await saveTikTokUsername(username);
    }

    final succeeded = await _runAction(
      () => _api.connectTikTok(tiktokUsername),
    );
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> _autoConnectTikTok() async {
    if (tiktokUsername.isEmpty ||
        health.tiktokConnected ||
        isBusy ||
        isAutoConnectingTikTok) {
      return;
    }

    isAutoConnectingTikTok = true;
    notifyListeners();

    final succeeded = await _runAction(
      () => _api.connectTikTok(tiktokUsername),
    );
    isAutoConnectingTikTok = false;
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> disconnectTikTok() async {
    final succeeded = await _runAction(_api.disconnectTikTok);
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> connectMinecraft() async {
    final succeeded = await _runAction(
      () => _api.connectMinecraft(
        minecraftHost: minecraftHost,
        minecraftPort: minecraftPort,
      ),
    );
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> _autoConnectMinecraft() async {
    if (minecraftHost.isEmpty ||
        health.minecraftConnected ||
        isBusy ||
        isAutoConnectingMinecraft) {
      return;
    }

    isAutoConnectingMinecraft = true;
    notifyListeners();

    final succeeded = await _runAction(
      () => _api.connectMinecraft(
        minecraftHost: minecraftHost,
        minecraftPort: minecraftPort,
      ),
    );
    isAutoConnectingMinecraft = false;
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> testMinecraftCommand() async {
    final succeeded = await _runAction(
      () => _api.executeMinecraftCommand(
        'say Nivroy TIKI-TIKI conectado por {user}',
        username: tiktokUsername.isEmpty ? 'dashboard' : tiktokUsername,
        minecraftHost: minecraftHost,
        minecraftPort: minecraftPort,
      ),
    );
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> testRule(MinecraftRule rule) async {
    final succeeded = await _runAction(
      () => _api.executeMinecraftCommand(
        rule.command,
        username: tiktokUsername.isEmpty ? 'rules' : tiktokUsername,
        minecraftHost: minecraftHost,
        minecraftPort: minecraftPort,
      ),
    );
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> createRule({
    required String eventType,
    required String trigger,
    required String command,
    required String target,
    bool enabled = true,
  }) async {
    final succeeded = await _runAction(
      () => _api.saveRule(
        eventType: eventType,
        trigger: trigger,
        command: command,
        target: target,
        enabled: enabled,
      ),
    );
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> updateRule({
    required String id,
    required String eventType,
    required String trigger,
    required String command,
    required String target,
    required bool enabled,
  }) async {
    final succeeded = await _runAction(
      () => _api.updateRule(
        id: id,
        eventType: eventType,
        trigger: trigger,
        command: command,
        target: target,
        enabled: enabled,
      ),
    );
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> toggleRule(MinecraftRule rule, bool enabled) async {
    final succeeded = await _runAction(() async {
      await _api.setRuleEnabled(id: rule.id, enabled: enabled);
    });
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> deleteRule(MinecraftRule rule) async {
    final succeeded = await _runAction(() => _api.deleteRule(rule.id));
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    isBusy = true;
    lastError = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (error) {
      lastError = error.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  String _normalizeTikTokUsername(String username) {
    return username.trim().replaceFirst('@', '');
  }

  void _setMinecraftConnection(String host, String port) {
    final nextHost = host.trim();
    final nextPort = int.tryParse(port.trim());

    if (nextHost.isNotEmpty) {
      minecraftHost = nextHost;
    }

    if (nextPort != null && nextPort >= 1 && nextPort <= 65535) {
      minecraftPort = nextPort;
    }
  }

  void _handleEvent(AppEvent event) {
    events = [event, ...events].take(100).toList();
    if (event.type == 'connected' && event.source == 'websocket') {
      websocketConnected = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }
}
