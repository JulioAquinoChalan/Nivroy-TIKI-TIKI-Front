import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _minecraftConnectionTabController;
  late final TextEditingController _tiktokUsernameController;
  late final TextEditingController _serverTapUrlController;
  late final TextEditingController _serverTapKeyController;
  late final TextEditingController _exarotonTokenController;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _minecraftConnectionTabController = TabController(length: 2, vsync: this);
    _tiktokUsernameController = TextEditingController(
      text: appState.tiktokUsername,
    );
    _serverTapUrlController = TextEditingController(
      text: appState.serverTapUrl,
    );
    _serverTapKeyController = TextEditingController(
      text: appState.serverTapKey,
    );
    _exarotonTokenController = TextEditingController(
      text: appState.exarotonToken,
    );
  }

  @override
  void dispose() {
    _minecraftConnectionTabController.dispose();
    _tiktokUsernameController.dispose();
    _serverTapUrlController.dispose();
    _serverTapKeyController.dispose();
    _exarotonTokenController.dispose();
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
    if (_exarotonTokenController.text.isEmpty &&
        appState.exarotonToken.isNotEmpty) {
      _exarotonTokenController.text = appState.exarotonToken;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 2 : 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: MediaQuery.sizeOf(context).width > 700 ? 5.2 : 4.6,
          children: [
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
                  : appState.exarotonConnected
                  ? appState.exarotonServerName
                  : appState.serverTapConnected
                  ? 'ServerTap listo'
                  : 'Sin conexion',
              active: appState.serverTapConnected || appState.exarotonConnected,
              icon: Icons.sports_esports,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _TikTokConnectionCard(
          appState: appState,
          tiktokUsernameController: _tiktokUsernameController,
        ),
        const SizedBox(height: 16),
        _MinecraftConnectionTabs(
          controller: _minecraftConnectionTabController,
          localConnection: _LocalConnectionCard(
            appState: appState,
            serverTapUrlController: _serverTapUrlController,
            serverTapKeyController: _serverTapKeyController,
          ),
          exarotonConnection: _ExarotonConnectionCard(
            appState: appState,
            exarotonTokenController: _exarotonTokenController,
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

class _TikTokConnectionCard extends StatefulWidget {
  const _TikTokConnectionCard({
    required this.appState,
    required this.tiktokUsernameController,
  });

  final AppState appState;
  final TextEditingController tiktokUsernameController;

  @override
  State<_TikTokConnectionCard> createState() => _TikTokConnectionCardState();
}

class _TikTokConnectionCardState extends State<_TikTokConnectionCard> {
  bool get _hasTikTokUsername =>
      widget.tiktokUsernameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.tiktokUsernameController.addListener(_handleUsernameChanged);
  }

  @override
  void didUpdateWidget(covariant _TikTokConnectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tiktokUsernameController != widget.tiktokUsernameController) {
      oldWidget.tiktokUsernameController.removeListener(_handleUsernameChanged);
      widget.tiktokUsernameController.addListener(_handleUsernameChanged);
    }
  }

  @override
  void dispose() {
    widget.tiktokUsernameController.removeListener(_handleUsernameChanged);
    super.dispose();
  }

  void _handleUsernameChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final tiktokUsernameController = widget.tiktokUsernameController;
    final canConnect = !appState.isBusy && _hasTikTokUsername;
    final canDisconnect = !appState.isBusy && appState.health.tiktokConnected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConnectionHeader(
              icon: Icons.live_tv,
              title: 'Conexion TikTok Live',
              badge: appState.health.tiktokConnected ? 'Conectado' : 'Live',
              badgeIcon: Icons.sensors,
              active: appState.health.tiktokConnected,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 360,
                  child: TextField(
                    controller: tiktokUsernameController,
                    enabled: !appState.isBusy,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Usuario TikTok',
                      hintText: 'usuario_tiktok',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: canConnect
                        ? (value) => appState.connectTikTok(username: value)
                        : null,
                    onChanged: appState.saveTikTokUsername,
                  ),
                ),
                FilledButton.icon(
                  onPressed: canConnect
                      ? () => appState.connectTikTok(
                          username: tiktokUsernameController.text,
                        )
                      : null,
                  icon: const Icon(Icons.link),
                  label: const Text('Conectar TikTok'),
                ),
                OutlinedButton.icon(
                  onPressed: canDisconnect ? appState.disconnectTikTok : null,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Desconectar TikTok'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MinecraftConnectionTabs extends StatefulWidget {
  const _MinecraftConnectionTabs({
    required this.controller,
    required this.localConnection,
    required this.exarotonConnection,
  });

  final TabController controller;
  final Widget localConnection;
  final Widget exarotonConnection;

  @override
  State<_MinecraftConnectionTabs> createState() =>
      _MinecraftConnectionTabsState();
}

class _MinecraftConnectionTabsState extends State<_MinecraftConnectionTabs> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.controller.index;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: TabBar(
              controller: widget.controller,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
              onTap: (value) => setState(() => _selectedIndex = value),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.computer),
                      SizedBox(width: 8),
                      Text('Minecraft local'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_outlined),
                      SizedBox(width: 8),
                      Text('Minecraft Exaroton'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: _selectedIndex == 0
                    ? widget.localConnection
                    : widget.exarotonConnection,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalConnectionCard extends StatelessWidget {
  const _LocalConnectionCard({
    required this.appState,
    required this.serverTapUrlController,
    required this.serverTapKeyController,
  });

  final AppState appState;
  final TextEditingController serverTapUrlController;
  final TextEditingController serverTapKeyController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConnectionHeader(
          icon: Icons.router,
          title: 'Conexion ServerTap local',
          badge: 'Local',
          badgeIcon: Icons.lan_outlined,
          active: appState.serverTapConnected,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                controller: serverTapUrlController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'URL ServerTap local',
                  hintText: 'http://127.0.0.1:4567',
                  prefixIcon: Icon(Icons.router),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => appState.saveServerTapConnection(
                  url: value,
                  key: serverTapKeyController.text,
                ),
              ),
            ),
            SizedBox(
              width: 240,
              child: TextField(
                controller: serverTapKeyController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'API key local',
                  prefixIcon: Icon(Icons.key),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => appState.saveServerTapConnection(
                  url: serverTapUrlController.text,
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
            FilledButton.tonalIcon(
              onPressed: appState.isBusy ? null : appState.connectServerTap,
              icon: const Icon(Icons.router),
              label: const Text('Conectar local'),
            ),
            OutlinedButton.icon(
              onPressed: appState.isBusy ? null : appState.testServerTapCommand,
              icon: const Icon(Icons.terminal),
              label: const Text('Probar comando'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExarotonConnectionCard extends StatelessWidget {
  const _ExarotonConnectionCard({
    required this.appState,
    required this.exarotonTokenController,
  });

  final AppState appState;
  final TextEditingController exarotonTokenController;

  @override
  Widget build(BuildContext context) {
    final selectedServerId =
        appState.exarotonServers.any(
          (server) => server.id == appState.exarotonServerId,
        )
        ? appState.exarotonServerId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConnectionHeader(
          icon: Icons.cloud_outlined,
          title: 'Conexion por API Exaroton',
          badge: appState.exarotonConnected ? 'Conectado' : 'API externa',
          badgeIcon: Icons.cloud_queue,
          active: appState.exarotonConnected,
        ),
        const SizedBox(height: 16),
        const _ExarotonInstructions(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: exarotonTokenController,
                enabled: !appState.isBusy && !appState.isLoadingExarotonServers,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Token Exaroton',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => appState.saveExarotonConnection(
                  token: value,
                  serverId: appState.exarotonServerId,
                ),
              ),
            ),
            SizedBox(
              width: 360,
              child: DropdownButtonFormField<String>(
                initialValue: selectedServerId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Servidor Exaroton',
                  prefixIcon: Icon(Icons.storage_outlined),
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Selecciona un servidor'),
                items: [
                  for (final server in appState.exarotonServers)
                    DropdownMenuItem(
                      value: server.id,
                      child: Text(
                        server.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: appState.isBusy || appState.isLoadingExarotonServers
                    ? null
                    : appState.selectExarotonServer,
              ),
            ),
            OutlinedButton.icon(
              onPressed: appState.isBusy || appState.isLoadingExarotonServers
                  ? null
                  : () => appState.loadExarotonServers(
                      token: exarotonTokenController.text,
                    ),
              icon: appState.isLoadingExarotonServers
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Cargar servidores'),
            ),
          ],
        ),
        if (appState.exarotonServerId.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'ID seleccionado: ${appState.exarotonServerId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.tonalIcon(
              onPressed: appState.isBusy || appState.isLoadingExarotonServers
                  ? null
                  : appState.connectExaroton,
              icon: const Icon(Icons.cloud_sync_outlined),
              label: const Text('Conectar Exaroton'),
            ),
            OutlinedButton.icon(
              onPressed: appState.isBusy || appState.isLoadingExarotonServers
                  ? null
                  : appState.testExarotonCommand,
              icon: const Icon(Icons.terminal),
              label: const Text('Enviar comando'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExarotonInstructions extends StatelessWidget {
  const _ExarotonInstructions();

  static const _steps = [
    'Crea tu servidor de Minecraft en Exaroton.',
    'Cambia el software del servidor a Paper/Bukkit.',
    'En el apartado de plugins, busca ServerTap e instalalo.',
    'Obtén tu token API desde Cuenta > Ajustes. Si no tienes uno, genera un token nuevo.',
    'Pega tu token API aqui y carga tus servidores.',
    'Selecciona tu servidor y conectalo a Exaroton.',
    'Crea tus reglas para empezar a reaccionar con los usuarios :D',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Guia rapida para Exaroton',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < _steps.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(_steps[index]),
                  ),
                ),
              ],
            ),
            if (index < _steps.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ConnectionHeader extends StatelessWidget {
  const _ConnectionHeader({
    required this.icon,
    required this.title,
    required this.badge,
    required this.badgeIcon,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String badge;
  final IconData badgeIcon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor = active
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = active
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(icon, color: active ? colorScheme.primary : colorScheme.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badgeIcon, size: 16, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                badge,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: foregroundColor),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
