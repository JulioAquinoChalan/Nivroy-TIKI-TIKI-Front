import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final TextEditingController _tiktokUsernameController;
  late final TextEditingController _serverTapUrlController;
  late final TextEditingController _serverTapKeyController;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _tiktokUsernameController = TextEditingController(
      text: appState.tiktokUsername,
    );
    _serverTapUrlController = TextEditingController(text: appState.serverTapUrl);
    _serverTapKeyController = TextEditingController(text: appState.serverTapKey);
  }

  @override
  void dispose() {
    _tiktokUsernameController.dispose();
    _serverTapUrlController.dispose();
    _serverTapKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (_tiktokUsernameController.text.isEmpty &&
        appState.tiktokUsername.isNotEmpty) {
      _tiktokUsernameController.text = appState.tiktokUsername;
    }
    if (_serverTapUrlController.text.isEmpty &&
        appState.serverTapUrl.isNotEmpty) {
      _serverTapUrlController.text = appState.serverTapUrl;
    }
    if (_serverTapKeyController.text.isEmpty &&
        appState.serverTapKey.isNotEmpty) {
      _serverTapKeyController.text = appState.serverTapKey;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: MediaQuery.sizeOf(context).width > 700 ? 1.9 : 3.4,
          children: [
            _StatusCard(
              label: 'Backend',
              value: appState.health.backendOnline ? 'Online' : 'Offline',
              active: appState.health.backendOnline,
              icon: Icons.dns,
            ),
            _StatusCard(
              label: 'TikTok Live',
              value: appState.isAutoConnectingTikTok
                  ? 'Conectando...'
                  : appState.health.tiktokConnected
                  ? 'Conectado'
                  : 'Desconectado',
              active: appState.health.tiktokConnected,
              icon: Icons.live_tv,
            ),
            _StatusCard(
              label: 'Minecraft',
              value: appState.isAutoConnectingServerTap
                  ? 'Conectando...'
                  : appState.serverTapConnected
                  ? 'ServerTap listo'
                  : 'Sin conexion',
              active: appState.serverTapConnected,
              icon: Icons.sports_esports,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conexion local',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 420,
                      child: TextField(
                        controller: _tiktokUsernameController,
                        enabled: !appState.isBusy,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de usuario TikTok',
                          hintText: 'usuario_tiktok',
                          prefixIcon: Icon(Icons.alternate_email),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) =>
                            appState.connectTikTok(username: value),
                        onChanged: appState.saveTikTokUsername,
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: _serverTapUrlController,
                        enabled: !appState.isBusy,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'URL ServerTap',
                          hintText: 'http://127.0.0.1:4567',
                          prefixIcon: Icon(Icons.router),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => appState.saveServerTapConnection(
                          url: value,
                          key: _serverTapKeyController.text,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _serverTapKeyController,
                        enabled: !appState.isBusy,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'API key ServerTap',
                          prefixIcon: Icon(Icons.key),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => appState.saveServerTapConnection(
                          url: _serverTapUrlController.text,
                          key: value,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: appState.isBusy
                          ? null
                          : () => appState.connectTikTok(
                              username: _tiktokUsernameController.text,
                            ),
                      icon: const Icon(Icons.link),
                      label: const Text('Conectar TikTok'),
                    ),
                    OutlinedButton.icon(
                      onPressed: appState.isBusy
                          ? null
                          : appState.disconnectTikTok,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Desconectar TikTok'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: appState.isBusy
                          ? null
                          : appState.connectServerTap,
                      icon: const Icon(Icons.router),
                      label: const Text('Conectar ServerTap'),
                    ),
                    OutlinedButton.icon(
                      onPressed: appState.isBusy
                          ? null
                          : appState.testServerTapCommand,
                      icon: const Icon(Icons.terminal),
                      label: const Text('Probar comando'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (appState.lastError != null) ...[
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(appState.lastError!),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.value,
    required this.active,
    required this.icon,
  });

  final String label;
  final String value;
  final bool active;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.greenAccent : Colors.redAccent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
