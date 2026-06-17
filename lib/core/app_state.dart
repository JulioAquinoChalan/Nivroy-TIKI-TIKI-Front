import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_event.dart';
import '../models/exaroton_server.dart';
import '../models/health_status.dart';
import '../models/minecraft_rule.dart';
import '../services/api_service.dart';
import '../services/servertap_service.dart';
import '../services/voice_service.dart';
import '../services/websocket_service.dart';

class AppState extends ChangeNotifier {
  static const _backendUrlKey = 'backend_url';
  static const _tiktokUsernameKey = 'tiktok_username';
  static const _serverTapUrlKey = 'servertap_url';
  static const _serverTapKeyKey = 'servertap_key';
  static const _exarotonTokenKey = 'exaroton_token';
  static const _exarotonServerIdKey = 'exaroton_server_id';
  static const _authIdTokenKey = 'auth_id_token';
  static const _authRefreshTokenKey = 'auth_refresh_token';
  static const _authExpiresAtKey = 'auth_expires_at';
  static const _authEmailKey = 'auth_email';
  static const _authUidKey = 'auth_uid';
  static const _languageCodeKey = 'language_code';
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
  static const _defaultServerTapHost = '127.0.0.1';
  static const _defaultServerTapPort = '4567';
  static const _defaultServerTapUrl =
      'http://$_defaultServerTapHost:$_defaultServerTapPort';
  static const _environmentServerTapKey = String.fromEnvironment(
    'SERVERTAP_KEY',
  );
  static const _environmentExarotonToken = String.fromEnvironment(
    'EXAROTON_API_TOKEN',
  );
  static const _environmentExarotonServerId = String.fromEnvironment(
    'EXAROTON_SERVER_ID',
  );

  final WebSocketService _webSocketService = WebSocketService();
  final VoiceService _voiceService = VoiceService();

  String backendUrl = _env('BACKEND_URL', _environmentBackendUrl);
  String tiktokUsername = _env('TIKTOK_USERNAME', _environmentTikTokUsername);
  String serverTapUrl = _initialServerTapUrl();
  String serverTapKey = _env('SERVERTAP_KEY', _environmentServerTapKey);
  String exarotonToken = _env('EXAROTON_API_TOKEN', _environmentExarotonToken);
  String exarotonServerId = _env(
    'EXAROTON_SERVER_ID',
    _environmentExarotonServerId,
  );
  String? lastError;
  bool isBusy = false;
  bool isAutoConnectingTikTok = false;
  bool isAutoConnectingServerTap = false;
  bool isLoadingExarotonServers = false;
  bool serverTapConnected = false;
  String serverTapServerName = '';
  bool exarotonConnected = false;
  String exarotonServerName = '';
  bool isInitialized = false;
  bool isAuthenticated = false;
  bool isEmailVerified = false;
  bool websocketConnected = false;
  String languageCode = 'es';
  String authEmail = '';
  String authUid = '';
  String _idToken = '';
  String _refreshToken = '';
  DateTime? _tokenExpiresAt;
  Timer? _errorTimer;
  HealthStatus health = HealthStatus.offline();
  List<AppEvent> events = [];
  List<MinecraftRule> rules = [];
  List<ExarotonServer> exarotonServers = [];

  static String _env(String key, String fallback) {
    final String? value;
    try {
      value = dotenv.env[key]?.trim();
    } catch (_) {
      return fallback;
    }
    return value == null || value.isEmpty ? fallback : value;
  }

  static String _initialServerTapUrl() {
    final url = _env('SERVERTAP_URL', _environmentServerTapUrl);
    return _normalizeServerTapUrl(url);
  }

  static String _normalizeServerTapUrl(String url) {
    final trimmed = url.trim();
    final rawUrl = trimmed.isEmpty ? _defaultServerTapUrl : trimmed;
    final value = rawUrl.contains('://') ? rawUrl : 'http://$rawUrl';
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return _defaultServerTapUrl;
    }

    final host = uri.host.trim().isEmpty ? _defaultServerTapHost : uri.host;
    final port = uri.hasPort ? uri.port.toString() : _defaultServerTapPort;
    return 'http://$host:${_normalizeServerTapPort(port)}';
  }

  static String _normalizeServerTapPort(String port) {
    final parsed = int.tryParse(port.trim());
    if (parsed == null || parsed < 1 || parsed > 65535) {
      return _defaultServerTapPort;
    }
    return parsed.toString();
  }

  static String _normalizeLanguageCode(String value) {
    return switch (value.trim().toLowerCase()) {
      'en' => 'en',
      _ => 'es',
    };
  }

  static String composeServerTapUrl({
    required String host,
    required String port,
  }) {
    return _normalizeServerTapUrl(
      '${host.trim().isEmpty ? _defaultServerTapHost : host.trim()}:'
      '${_normalizeServerTapPort(port)}',
    );
  }

  ApiService get _api => ApiService(backendUrl, idToken: _idToken);
  ServerTapService get _serverTap =>
      ServerTapService(baseUrl: serverTapUrl, key: serverTapKey);
  String get serverTapHost => Uri.parse(serverTapUrl).host.isEmpty
      ? _defaultServerTapHost
      : Uri.parse(serverTapUrl).host;
  String get serverTapPort => Uri.parse(serverTapUrl).hasPort
      ? Uri.parse(serverTapUrl).port.toString()
      : _defaultServerTapPort;
  String get overlayRulesUrl {
    final uri = Uri.parse(
      '${backendUrl.replaceAll(RegExp(r'/$'), '')}/overlay/rules',
    );
    return _withOverlayUser(uri).toString();
  }

  String get overlayAnnouncementsUrl {
    final uri = Uri.parse(
      '${backendUrl.replaceAll(RegExp(r'/$'), '')}/overlay/announcements',
    );
    return _withOverlayUser(uri).toString();
  }

  String get overlayLiveStudioUrl {
    final uri = Uri.tryParse(backendUrl);
    if (uri == null) {
      return overlayRulesUrl;
    }

    final host = uri.host == 'localhost' ? '127.0.0.1' : uri.host;
    return _withOverlayUser(
      uri.replace(host: host, path: '/overlay/rules'),
    ).toString();
  }

  String get overlayAnnouncementsLiveStudioUrl {
    final uri = Uri.tryParse(backendUrl);
    if (uri == null) {
      return overlayAnnouncementsUrl;
    }

    final host = uri.host == 'localhost' ? '127.0.0.1' : uri.host;
    return _withOverlayUser(
      uri.replace(host: host, path: '/overlay/announcements'),
    ).toString();
  }

  Uri _withOverlayUser(Uri uri) {
    if (authUid.isEmpty) {
      return uri.replace(query: '');
    }

    return uri.replace(
      queryParameters: {...uri.queryParameters, 'uid': authUid},
    );
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    backendUrl = prefs.getString(_backendUrlKey) ?? backendUrl;
    tiktokUsername = prefs.getString(_tiktokUsernameKey) ?? tiktokUsername;
    serverTapUrl = _normalizeServerTapUrl(
      prefs.getString(_serverTapUrlKey) ?? serverTapUrl,
    );
    serverTapKey = prefs.getString(_serverTapKeyKey) ?? serverTapKey;
    exarotonToken = prefs.getString(_exarotonTokenKey) ?? exarotonToken;
    exarotonServerId =
        prefs.getString(_exarotonServerIdKey) ?? exarotonServerId;
    languageCode = _normalizeLanguageCode(
      prefs.getString(_languageCodeKey) ?? languageCode,
    );
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
      await _autoConnectExaroton();
    }
    isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguageCode(String value) async {
    final nextLanguageCode = _normalizeLanguageCode(value);
    if (languageCode == nextLanguageCode) {
      return;
    }

    languageCode = nextLanguageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
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
        _clearError();
      }
    } catch (error) {
      health = HealthStatus.offline();
      _setError(error);
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
    await refresh();
  }

  Future<void> saveTikTokUsername(String username) async {
    tiktokUsername = _normalizeTikTokUsername(username);
    _clearError();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tiktokUsernameKey, tiktokUsername);

    notifyListeners();
  }

  Future<void> saveServerTapConnection({
    required String url,
    required String key,
  }) async {
    _setServerTapConnection(url, key);
    _clearError();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverTapUrlKey, serverTapUrl);
    await prefs.setString(_serverTapKeyKey, serverTapKey);

    notifyListeners();
  }

  Future<void> saveServerTapEndpoint({
    required String host,
    required String port,
    required String key,
  }) {
    return saveServerTapConnection(
      url: composeServerTapUrl(host: host, port: port),
      key: key,
    );
  }

  Future<void> saveExarotonConnection({
    required String token,
    required String serverId,
  }) async {
    exarotonToken = token.trim();
    exarotonServerId = serverId.trim();
    exarotonConnected = false;
    exarotonServerName = '';
    _clearError();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exarotonTokenKey, exarotonToken);
    await prefs.setString(_exarotonServerIdKey, exarotonServerId);

    notifyListeners();
  }

  Future<void> loadExarotonServers({String? token}) async {
    if (!_canUseVerifiedAccount()) {
      return;
    }

    final nextToken = token?.trim() ?? exarotonToken;
    if (nextToken.isEmpty) {
      _setError('Ingresa el token de Exaroton.');
      notifyListeners();
      return;
    }

    isLoadingExarotonServers = true;
    _clearError();
    notifyListeners();

    try {
      await _refreshSessionIfNeeded();
      exarotonToken = nextToken;
      exarotonServers = await _api.getExarotonServers(token: exarotonToken);
      if (exarotonServerId.isEmpty && exarotonServers.isNotEmpty) {
        exarotonServerId = exarotonServers.first.id;
      }
      await _persistExarotonConnection();
    } catch (error) {
      _setError(error);
    } finally {
      isLoadingExarotonServers = false;
      notifyListeners();
    }
  }

  Future<void> selectExarotonServer(String? serverId) async {
    exarotonServerId = serverId?.trim() ?? '';
    exarotonConnected = false;
    exarotonServerName = '';
    _clearError();
    await _persistExarotonConnection();
    notifyListeners();
  }

  Future<void> connectExaroton() async {
    if (!_canUseVerifiedAccount()) {
      return;
    }
    final succeeded = await _runAction(_connectExaroton);
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> testExarotonCommand() async {
    if (!_canUseVerifiedAccount()) {
      return;
    }
    final succeeded = await _runAction(
      () => _executeExarotonCommand(
        'say Nivroy TIKI-TIKI conectado por Exaroton',
      ),
    );
    await refresh(clearErrorOnSuccess: succeeded);
  }

  void connectWebSocket() {
    try {
      _webSocketService.connect(
        backendUrl,
        onEvent: _handleEvent,
        onError: (error) {
          websocketConnected = false;
          _setError(error);
          notifyListeners();
        },
      );
      websocketConnected = true;
      _clearError();
    } catch (error) {
      websocketConnected = false;
      _setError(error);
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

  Future<void> disconnectServerTap() async {
    serverTapConnected = false;
    serverTapServerName = '';
    _clearError();
    notifyListeners();
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
    final testCommand = _testCommandForRule(rule);
    final succeeded = await _runAction(() async {
      if (exarotonConnected) {
        await _executeExarotonCommand(testCommand);
      } else {
        await _executeServerTapCommand(testCommand);
        await _api.sendRuleOverlayTest(ruleId: rule.id, command: testCommand);
      }
      await _speakRuleForTest(rule);
    });
    await refresh(clearErrorOnSuccess: succeeded);
  }

  Future<void> createRule({
    required String eventType,
    required String trigger,
    required String command,
    required String target,
    required bool voiceEnabled,
    required String voiceMessage,
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
        voiceEnabled: voiceEnabled,
        voiceMessage: voiceMessage,
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
    required bool voiceEnabled,
    required String voiceMessage,
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
        voiceEnabled: voiceEnabled,
        voiceMessage: voiceMessage,
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
      await _saveSessionAndReloadUser(session);
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
      await _saveSessionAndReloadUser(session);
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
    _clearError();
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    isBusy = true;
    _clearError();
    notifyListeners();

    try {
      if (isAuthenticated) {
        await _refreshSessionIfNeeded();
      }
      await action();
      return true;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  bool _canUseVerifiedAccount() {
    if (!isAuthenticated) {
      _setError('Inicia sesion para continuar.');
      notifyListeners();
      return false;
    }
    if (!isEmailVerified) {
      _setError('Verifica tu correo antes de continuar.');
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

  Future<void> _saveSessionAndReloadUser(AuthSession session) async {
    await _saveSession(session);
    await _refreshSession(force: true);
  }

  String _normalizeTikTokUsername(String username) {
    return username.trim().replaceFirst('@', '');
  }

  void _setServerTapConnection(String url, String key) {
    serverTapUrl = _normalizeServerTapUrl(url);
    serverTapKey = key.trim();
  }

  Future<void> _persistExarotonConnection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exarotonTokenKey, exarotonToken);
    await prefs.setString(_exarotonServerIdKey, exarotonServerId);
  }

  void _handleEvent(AppEvent event) {
    events = [event, ...events].take(100).toList();
    if (event.type == 'connected' && event.source == 'websocket') {
      websocketConnected = true;
    }
    unawaited(_speakRulesForEvent(event));
    unawaited(_runRulesForEvent(event));
    notifyListeners();
  }

  Future<void> _connectServerTap() async {
    final server = await _serverTap.getServer();
    serverTapConnected = true;
    serverTapServerName = server['name']?.toString() ?? 'ServerTap';
    exarotonConnected = false;
  }

  Future<void> _executeServerTapCommand(String command) async {
    await _serverTap.runCommand(command);
    serverTapConnected = true;
    exarotonConnected = false;
  }

  Future<void> _autoConnectExaroton() async {
    if (exarotonToken.isEmpty ||
        exarotonServerId.isEmpty ||
        exarotonConnected ||
        isBusy) {
      return;
    }

    await _runAction(_connectExaroton);
  }

  Future<void> _connectExaroton() async {
    if (exarotonToken.isEmpty) {
      throw Exception('Ingresa el token de Exaroton.');
    }
    if (exarotonServerId.isEmpty) {
      if (exarotonServers.isEmpty) {
        exarotonServers = await _api.getExarotonServers(token: exarotonToken);
      }
      if (exarotonServers.isNotEmpty) {
        exarotonServerId = exarotonServers.first.id;
      }
    }
    if (exarotonServerId.isEmpty) {
      throw Exception('Selecciona un servidor Exaroton.');
    }

    await _executeExarotonCommand(
      'say Nivroy TIKI-TIKI conectado por Exaroton',
    );
  }

  Future<void> _executeExarotonCommand(String command) async {
    await _api.sendMinecraftCommand(
      provider: 'exaroton',
      command: command,
      exarotonToken: exarotonToken,
      serverId: exarotonServerId,
    );
    exarotonConnected = true;
    serverTapConnected = false;
    ExarotonServer? selectedServer;
    for (final server in exarotonServers) {
      if (server.id == exarotonServerId) {
        selectedServer = server;
        break;
      }
    }
    exarotonServerName = selectedServer?.name ?? 'Exaroton';
    await _persistExarotonConnection();
  }

  Future<void> _runRulesForEvent(AppEvent event) async {
    if (!_canUseVerifiedAccount() || !serverTapConnected || exarotonConnected) {
      return;
    }

    final matchedRules = rules.where((rule) => _matchesEvent(rule, event));
    for (final rule in matchedRules) {
      try {
        await _executeServerTapCommand(_commandForEvent(rule.command, event));
      } catch (error) {
        _setError(error);
        serverTapConnected = false;
        notifyListeners();
        return;
      }
    }
  }

  Future<void> _speakRulesForEvent(AppEvent event) async {
    if (!_isTikTokRuleEvent(event)) {
      return;
    }

    final matchedRules = rules.where(
      (rule) => rule.voiceEnabled && _matchesEvent(rule, event),
    );
    for (final rule in matchedRules) {
      final message = _commandForEvent(rule.voiceMessage, event);
      if (message.trim().isEmpty) {
        continue;
      }
      await _voiceService.speak(message);
    }
  }

  Future<void> _speakRuleForTest(MinecraftRule rule) async {
    if (!rule.voiceEnabled) {
      return;
    }

    final message = _testCommandText(rule.voiceMessage, rule);
    await _voiceService.speak(message);
  }

  String _testCommandForRule(MinecraftRule rule) {
    return _testCommandText(rule.command, rule);
  }

  String _testCommandText(String value, MinecraftRule rule) {
    return value
        .replaceAll('{user}', 'test_user')
        .replaceAll('{username}', 'test_user')
        .replaceAll('{detail}', rule.trigger);
  }

  bool _isTikTokRuleEvent(AppEvent event) {
    return const {
      'gift',
      'like',
      'follow',
      'member',
      'share',
      'chat',
    }.contains(event.type);
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

  void _setError(Object error) {
    lastError = _formatError(error);
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 3), () {
      lastError = null;
      notifyListeners();
    });
  }

  void _clearError() {
    _errorTimer?.cancel();
    _errorTimer = null;
    lastError = null;
  }

  String _formatError(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Exception|Bad state):\s*'), '')
        .replaceFirst(RegExp(r'^TimeoutException after .+?:\s*'), '');
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }
}
