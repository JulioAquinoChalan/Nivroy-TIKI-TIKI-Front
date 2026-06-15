import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_event.dart';
import '../models/health_status.dart';
import '../models/minecraft_rule.dart';
import '../services/api_service.dart';
import '../services/servertap_service.dart';
import '../services/websocket_service.dart';

class AppState extends ChangeNotifier {
  static const _backendUrlKey = 'backend_url';
  static const _tiktokUsernameKey = 'tiktok_username';
  static const _serverTapUrlKey = 'servertap_url';
  static const _serverTapKeyKey = 'servertap_key';
  static const _authIdTokenKey = 'auth_id_token';
  static const _authRefreshTokenKey = 'auth_refresh_token';
  static const _authExpiresAtKey = 'auth_expires_at';
  static const _authEmailKey = 'auth_email';
  static const _authUidKey = 'auth_uid';
  static const _environmentBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const _environmentTikTokUsername = String.fromEnvironment(
    'TIKTOK_USERNAME',
  );
  static const _environmentServerTapUrl = String.fromEnvironment(
    'SERVERTAP_URL',
    defaultValue: 'http://127.0.0.1:4567',
  );
  static const _environmentServerTapKey = String.fromEnvironment(
    'SERVERTAP_KEY',
  );

  final WebSocketService _webSocketService = WebSocketService();

  String backendUrl = _env('BACKEND_URL', _environmentBackendUrl);
  String tiktokUsername = _env('TIKTOK_USERNAME', _environmentTikTokUsername);
  String serverTapUrl = _env('SERVERTAP_URL', _environmentServerTapUrl);
  String serverTapKey = _env('SERVERTAP_KEY', _environmentServerTapKey);
  String? lastError;
  bool isBusy = false;
  bool isAutoConnectingTikTok = false;
  bool isAutoConnectingServerTap = false;
  bool serverTapConnected = false;
  String serverTapServerName = '';
  bool isInitialized = false;
  bool isAuthenticated = false;
  bool isEmailVerified = false;
  bool websocketConnected = false;
  String authEmail = '';
  String authUid = '';
  String _idToken = '';
  String _refreshToken = '';
  DateTime? _tokenExpiresAt;
  HealthStatus health = HealthStatus.offline();
  List<AppEvent> events = [];
  List<MinecraftRule> rules = [];

  static String _env(String key, String fallback) {
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  ApiService get _api => ApiService(backendUrl, idToken: _idToken);
  ServerTapService get _serverTap =>
      ServerTapService(baseUrl: serverTapUrl, key: serverTapKey);
  String get overlayRulesUrl {
    final uri = Uri.parse(
      '${backendUrl.replaceAll(RegExp(r'/$'), '')}/overlay/rules',
    );
    return _withOverlayUser(uri).toString();
  }

  String get overlayLiveStudioUrl {
    final uri = Uri.tryParse(backendUrl);
    if (uri == null) {
      return overlayRulesUrl;
    }

    final host = uri.host == 'localhost' ? '127.0.0.1' : uri.host;
    return _withOverlayUser(uri.replace(host: host, path: '/overlay/rules'))
        .toString();
  }

  Uri _withOverlayUser(Uri uri) {
    if (authUid.isEmpty) {
      return uri.replace(query: '');
    }

    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'uid': authUid,
    });
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    backendUrl = prefs.getString(_backendUrlKey) ?? backendUrl;
    tiktokUsername = prefs.getString(_tiktokUsernameKey) ?? tiktokUsername;
    serverTapUrl = prefs.getString(_serverTapUrlKey) ?? serverTapUrl;
    serverTapKey = prefs.getString(_serverTapKeyKey) ?? serverTapKey;
    _idToken = prefs.getString(_authIdTokenKey) ?? '';
    _refreshToken = prefs.getString(_authRefreshTokenKey) ?? '';
    authEmail = prefs.getString(_authEmailKey) ?? '';
    authUid = prefs.getString(_authUidKey) ?? '';
    final expiresAt = prefs.getInt(_authExpiresAtKey);
    _tokenExpiresAt = expiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(expiresAt);
    isAuthenticated = _idToken.isNotEmpty && _refreshToken.isNotEmpty;
    if (isAuthenticated) {
      try {
        await _refreshSession(force: true);
      } catch (_) {
        await _clearSession();
      }
    }
    await refresh();
    connectWebSocket();
    if (isAuthenticated && isEmailVerified) {
      await _autoConnectTikTok();
      await _autoConnectServerTap();
    }
    isInitialized = true;
    notifyListeners();
  }

  Future<void> refresh({bool clearErrorOnSuccess = true}) async {
    try {
      if (isAuthenticated) {
        await _refreshSessionIfNeeded();
      }
      health = await _api.getHealth();
      events = await _api.getEvents();
      rules = isAuthenticated && isEmailVerified ? await _api.getRules() : [];
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
    required String newServerTapUrl,
    required String newServerTapKey,
  }) async {
    backendUrl = newBackendUrl.trim().isEmpty
        ? backendUrl
        : newBackendUrl.trim();
    tiktokUsername = _normalizeTikTokUsername(newTikTokUsername);
    _setServerTapConnection(newServerTapUrl, newServerTapKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendUrlKey, backendUrl);
    await prefs.setString(_tiktokUsernameKey, tiktokUsername);
    await prefs.setString(_serverTapUrlKey, serverTapUrl);
    await prefs.setString(_serverTapKeyKey, serverTapKey);

    connectWebSocket();
    await connectServerTap();
    await refresh();
  }

  Future<void> saveTikTokUsername(String username) async {
    tiktokUsername = _normalizeTikTokUsername(username);
    lastError = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tiktokUsernameKey, tiktokUsername);

    notifyListeners();
  }

  Future<void> saveServerTapConnection({
    required String url,
    required String key,
  }) async {
    _setServerTapConnection(url, key);
    lastError = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverTapUrlKey, serverTapUrl);
    await prefs.setString(_serverTapKeyKey, serverTapKey);

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
    if (!_canUseVerifiedAccount()) {
      return;
    }
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
    if (!_canUseVerifiedAccount()) {
      return;
    }
    final succeeded = await _runAction(_api.disconnectTikTok);
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> connectServerTap() async {
    if (!_canUseVerifiedAccount()) {
      return;
    }
    final succeeded = await _runAction(_connectServerTap);
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> _autoConnectServerTap() async {
    if (serverTapUrl.isEmpty ||
        serverTapConnected ||
        isBusy ||
        isAutoConnectingServerTap) {
      return;
    }

    isAutoConnectingServerTap = true;
    notifyListeners();

    final succeeded = await _runAction(_connectServerTap);
    isAutoConnectingServerTap = false;
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> testServerTapCommand() async {
    if (!_canUseVerifiedAccount()) {
      return;
    }
    final succeeded = await _runAction(
      () => _executeServerTapCommand(
        'say Nivroy TIKI-TIKI conectado por ${tiktokUsername.isEmpty ? 'dashboard' : tiktokUsername}',
      ),
    );
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> testRule(MinecraftRule rule) async {
    if (!_canUseVerifiedAccount()) {
      return;
    }
    final succeeded = await _runAction(
      () => _executeServerTapCommand(rule.command),
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
    if (!_canUseVerifiedAccount()) {
      return;
    }
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
    if (!_canUseVerifiedAccount()) {
      return;
    }
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
    if (!_canUseVerifiedAccount()) {
      return;
    }
    final succeeded = await _runAction(() async {
      await _api.setRuleEnabled(id: rule.id, enabled: enabled);
    });
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> deleteRule(MinecraftRule rule) async {
    if (!_canUseVerifiedAccount()) {
      return;
    }
    final succeeded = await _runAction(() => _api.deleteRule(rule.id));
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> login({required String email, required String password}) async {
    final succeeded = await _runAction(() async {
      final session = await ApiService(
        backendUrl,
      ).login(email: email.trim(), password: password);
      await _saveSession(session);
    });
    if (succeeded) {
      await refresh();
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final succeeded = await _runAction(() async {
      final session = await ApiService(
        backendUrl,
      ).register(email: email.trim(), password: password);
      await _saveSession(session);
    });
    if (succeeded) {
      await refresh();
    }
  }

  Future<void> sendEmailVerification() async {
    final succeeded = await _runAction(_api.sendEmailVerification);
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> reloadAuthUser() async {
    final succeeded = await _runAction(() async {
      await _refreshSession(force: true);
    });
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authIdTokenKey);
    await prefs.remove(_authRefreshTokenKey);
    await prefs.remove(_authExpiresAtKey);
    await prefs.remove(_authEmailKey);
    await prefs.remove(_authUidKey);
    _idToken = '';
    _refreshToken = '';
    _tokenExpiresAt = null;
    authEmail = '';
    authUid = '';
    isAuthenticated = false;
    isEmailVerified = false;
    rules = [];
    lastError = null;
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    isBusy = true;
    lastError = null;
    notifyListeners();

    try {
      if (isAuthenticated) {
        await _refreshSessionIfNeeded();
      }
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

  bool _canUseVerifiedAccount() {
    if (!isAuthenticated) {
      lastError = 'Inicia sesion para continuar.';
      notifyListeners();
      return false;
    }
    if (!isEmailVerified) {
      lastError = 'Verifica tu correo antes de continuar.';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> _refreshSessionIfNeeded() async {
    final expiresAt = _tokenExpiresAt;
    if (expiresAt == null ||
        DateTime.now().isAfter(
          expiresAt.subtract(const Duration(minutes: 5)),
        )) {
      await _refreshSession();
    }
  }

  Future<void> _refreshSession({bool force = false}) async {
    if (_refreshToken.isEmpty) {
      return;
    }
    if (!force) {
      final expiresAt = _tokenExpiresAt;
      if (expiresAt != null &&
          DateTime.now().isBefore(
            expiresAt.subtract(const Duration(minutes: 5)),
          )) {
        return;
      }
    }

    final session = await ApiService(backendUrl).refreshAuth(_refreshToken);
    await _saveSession(session);
  }

  Future<void> _saveSession(AuthSession session) async {
    _idToken = session.idToken;
    _refreshToken = session.refreshToken;
    authEmail = session.email;
    authUid = session.uid;
    isAuthenticated = _idToken.isNotEmpty && _refreshToken.isNotEmpty;
    isEmailVerified = session.emailVerified;
    _tokenExpiresAt = DateTime.now().add(Duration(seconds: session.expiresIn));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authIdTokenKey, _idToken);
    await prefs.setString(_authRefreshTokenKey, _refreshToken);
    await prefs.setString(_authEmailKey, authEmail);
    await prefs.setString(_authUidKey, authUid);
    await prefs.setInt(
      _authExpiresAtKey,
      _tokenExpiresAt!.millisecondsSinceEpoch,
    );
  }

  String _normalizeTikTokUsername(String username) {
    return username.trim().replaceFirst('@', '');
  }

  void _setServerTapConnection(String url, String key) {
    final nextUrl = url.trim();
    if (nextUrl.isNotEmpty) {
      serverTapUrl = nextUrl;
    }
    serverTapKey = key.trim();
  }

  void _handleEvent(AppEvent event) {
    events = [event, ...events].take(100).toList();
    if (event.type == 'connected' && event.source == 'websocket') {
      websocketConnected = true;
    }
    unawaited(_runRulesForEvent(event));
    notifyListeners();
  }

  Future<void> _connectServerTap() async {
    final server = await _serverTap.getServer();
    serverTapConnected = true;
    serverTapServerName = server['name']?.toString() ?? 'ServerTap';
  }

  Future<void> _executeServerTapCommand(String command) async {
    await _serverTap.runCommand(command);
    serverTapConnected = true;
  }

  Future<void> _runRulesForEvent(AppEvent event) async {
    if (!_canUseVerifiedAccount() || !serverTapConnected) {
      return;
    }

    final matchedRules = rules.where((rule) => _matchesEvent(rule, event));
    for (final rule in matchedRules) {
      try {
        await _executeServerTapCommand(_commandForEvent(rule.command, event));
      } catch (error) {
        lastError = error.toString();
        serverTapConnected = false;
        notifyListeners();
        return;
      }
    }
  }

  bool _matchesEvent(MinecraftRule rule, AppEvent event) {
    if (!rule.enabled || rule.eventType != event.type) {
      return false;
    }

    final trigger = rule.trigger.trim().toLowerCase();
    if (trigger.isEmpty ||
        rule.eventType == 'like' ||
        rule.eventType == 'follow' ||
        rule.eventType == 'member' ||
        rule.eventType == 'share') {
      return true;
    }

    final detail = event.detail?.trim().toLowerCase() ?? '';
    return detail == trigger || detail.contains(trigger);
  }

  String _commandForEvent(String command, AppEvent event) {
    final username = event.user ?? tiktokUsername;
    return command
        .replaceAll('{user}', username)
        .replaceAll('{username}', username)
        .replaceAll('{detail}', event.detail ?? '');
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }
}
