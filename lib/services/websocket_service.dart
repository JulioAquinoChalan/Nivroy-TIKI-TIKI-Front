import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/app_event.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  bool get isConnected => _channel != null;

  void connect(
    String backendUrl, {
    required void Function(AppEvent event) onEvent,
    required void Function(Object error) onError,
  }) {
    disconnect();

    final uri = Uri.parse(backendUrl);
    final wsUri = uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');
    _channel = WebSocketChannel.connect(wsUri);
    _subscription = _channel!.stream.listen(
      (message) {
        final decoded = jsonDecode(message as String) as Map<String, dynamic>;
        onEvent(AppEvent.fromJson(decoded));
      },
      onError: onError,
      onDone: disconnect,
    );
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }
}
