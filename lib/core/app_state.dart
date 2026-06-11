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
  static const _authIdTokenKey = 'auth_id_token';
  static const _authRefreshTokenKey = 'auth_refresh_token';
  static const _authExpiresAtKey = 'auth_expires_at';
  static const _authEmailKey = 'auth_email';
  static const _authUidKey = 'auth_uid';
  static const _defaultBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const _defaultTikTokUsername = String.fromEnvironment(
    'TIKTOK_USERNAME',
  );
  static const _defaultMinecraftHost = String.fromEnvironment(
    'MINECRAFT_HOST',
    defaultValue: '127.0.0.1',
  );
  static const _defaultMinecraftPort = int.fromEnvironment(
    'MINECRAFT_PORT',
    defaultValue: 25575,
  );

  final WebSocketService _webSocketService = WebSocketService();

  String backendUrl = _defaultBackendUrl;
  String tiktokUsername = _defaultTikTokUsername;
  String minecraftHost = _defaultMinecraftHost;
  int minecraftPort = _defaultMinecraftPort;
  String? lastError;
  bool isBusy = false;
  bool isAutoConnectingTikTok = false;
  bool isAutoConnectingMinecraft = false;
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

  ApiService get _api => ApiService(backendUrl, idToken: _idToken);
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
    tiktokUsername = prefs.getString(_tiktokUsernameKey) ?? tiktokUsername;
    minecraftHost = prefs.getString(_minecraftHostKey) ?? minecraftHost;
    minecraftPort = prefs.getInt(_minecraftPortKey) ?? minecraftPort;
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
      await _autoConnectMinecraft();
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

  Future<void> connectMinecraft() async {
    if (!_canUseVerifiedAccount()) {
      return;
    }
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
    if (!_canUseVerifiedAccount()) {
      return;
    }
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
    if (!_canUseVerifiedAccount()) {
      return;
    }
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
