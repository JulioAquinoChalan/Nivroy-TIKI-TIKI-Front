import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_design.dart';
import '../../core/app_state.dart';
import '../../l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _minecraftConnectionTabController;
  late final TextEditingController _tiktokUsernameController;
  late final TextEditingController _serverTapHostController;
  late final TextEditingController _serverTapPortController;
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
    _serverTapHostController = TextEditingController(
      text: appState.serverTapHost,
    );
    _serverTapPortController = TextEditingController(
      text: appState.serverTapPort,
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
    _serverTapHostController.dispose();
    _serverTapPortController.dispose();
    _serverTapKeyController.dispose();
    _exarotonTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = context.l10n;

    if (_tiktokUsernameController.text.isEmpty &&
        appState.tiktokUsername.isNotEmpty) {
      _tiktokUsernameController.text = appState.tiktokUsername;
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
        PageHeader(
          icon: Icons.hub_outlined,
          title: l10n.t('dashboard.title'),
          subtitle: l10n.t('dashboard.subtitle'),
          trailing: StatusPill(
            label: appState.websocketConnected
                ? l10n.t('dashboard.systemOnline')
                : l10n.t('dashboard.systemOffline'),
            icon: appState.websocketConnected
                ? Icons.sensors
                : Icons.sensors_off_outlined,
            active: appState.websocketConnected,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 2 : 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: MediaQuery.sizeOf(context).width > 700 ? 4.1 : 3.4,
          children: [
            _StatusCard(
              label: 'TikTok Live',
              value: appState.isAutoConnectingTikTok
                  ? l10n.t('status.connecting')
                  : appState.health.tiktokConnected
                  ? l10n.t('status.connected')
                  : l10n.t('status.disconnected'),
              active: appState.health.tiktokConnected,
              icon: Icons.live_tv,
            ),
            _StatusCard(
              label: 'Minecraft',
              value: appState.isAutoConnectingServerTap
                  ? l10n.t('status.connecting')
                  : appState.exarotonConnected
                  ? appState.exarotonServerName
                  : appState.serverTapConnected
                  ? l10n.t('dashboard.serverTapReady')
                  : l10n.t('status.noConnection'),
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
            serverTapHostController: _serverTapHostController,
            serverTapPortController: _serverTapPortController,
            serverTapKeyController: _serverTapKeyController,
          ),
          exarotonConnection: _ExarotonConnectionCard(
            appState: appState,
            exarotonTokenController: _exarotonTokenController,
          ),
        ),
        if (appState.lastError != null) ...[
          const SizedBox(height: 16),
          SectionCard(
            padding: const EdgeInsets.all(16),
            child: Text(appState.lastError!),
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
    final l10n = context.l10n;
    final canConnect = !appState.isBusy && _hasTikTokUsername;
    final canDisconnect = !appState.isBusy && appState.health.tiktokConnected;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConnectionHeader(
            icon: Icons.live_tv,
            title: l10n.t('dashboard.tiktokConnection'),
            badge: appState.health.tiktokConnected
                ? l10n.t('status.connected')
                : 'Live',
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
                  decoration: InputDecoration(
                    labelText: l10n.t('dashboard.tiktokUser'),
                    hintText: 'usuario_tiktok',
                    prefixIcon: const Icon(Icons.alternate_email),
                    border: const OutlineInputBorder(),
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
                label: Text(l10n.t('dashboard.connectTikTok')),
              ),
              OutlinedButton.icon(
                onPressed: canDisconnect ? appState.disconnectTikTok : null,
                icon: const Icon(Icons.link_off),
                label: Text(l10n.t('dashboard.disconnectTikTok')),
              ),
            ],
          ),
        ],
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
    final l10n = context.l10n;

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
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.computer),
                      const SizedBox(width: 8),
                      Text(l10n.t('dashboard.minecraftLocal')),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_outlined),
                      const SizedBox(width: 8),
                      Text(l10n.t('dashboard.minecraftExaroton')),
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
    required this.serverTapHostController,
    required this.serverTapPortController,
    required this.serverTapKeyController,
  });

  final AppState appState;
  final TextEditingController serverTapHostController;
  final TextEditingController serverTapPortController;
  final TextEditingController serverTapKeyController;

  void _saveConnection() {
    appState.saveServerTapEndpoint(
      host: serverTapHostController.text,
      port: serverTapPortController.text,
      key: serverTapKeyController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConnectionHeader(
          icon: Icons.router,
          title: l10n.t('dashboard.localServerTapConnection'),
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
                controller: serverTapHostController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.t('dashboard.localServerTapIp'),
                  hintText: '127.0.0.1',
                  prefixIcon: const Icon(Icons.router),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _saveConnection(),
              ),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                controller: serverTapPortController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.t('dashboard.port'),
                  hintText: '4567',
                  prefixIcon: const Icon(Icons.numbers),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _saveConnection(),
              ),
            ),
            SizedBox(
              width: 240,
              child: TextField(
                controller: serverTapKeyController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.t('dashboard.localApiKey'),
                  prefixIcon: const Icon(Icons.key),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _saveConnection(),
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
              label: Text(l10n.t('dashboard.connectLocal')),
            ),
            OutlinedButton.icon(
              onPressed: appState.serverTapConnected && !appState.isBusy
                  ? appState.disconnectServerTap
                  : null,
              icon: const Icon(Icons.link_off),
              label: Text(l10n.t('common.disconnect')),
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
    final l10n = context.l10n;
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
          title: l10n.t('dashboard.exarotonApiConnection'),
          badge: appState.exarotonConnected
              ? l10n.t('status.connected')
              : l10n.t('dashboard.externalApi'),
          badgeIcon: Icons.cloud_queue,
          active: appState.exarotonConnected,
        ),
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
                decoration: InputDecoration(
                  labelText: l10n.t('dashboard.exarotonToken'),
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  border: const OutlineInputBorder(),
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
                decoration: InputDecoration(
                  labelText: l10n.t('dashboard.exarotonServer'),
                  prefixIcon: const Icon(Icons.storage_outlined),
                  border: const OutlineInputBorder(),
                ),
                hint: Text(l10n.t('dashboard.selectServer')),
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
              label: Text(l10n.t('dashboard.loadServers')),
            ),
          ],
        ),
        if (appState.exarotonServerId.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.t('dashboard.selectedId', {'id': appState.exarotonServerId}),
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
              label: Text(l10n.t('dashboard.connectExaroton')),
            ),
            OutlinedButton.icon(
              onPressed: appState.isBusy || appState.isLoadingExarotonServers
                  ? null
                  : appState.testExarotonCommand,
              icon: const Icon(Icons.terminal),
              label: Text(l10n.t('dashboard.sendCommand')),
            ),
          ],
        ),
      ],
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
    return Row(
      children: [
        Icon(icon, color: active ? colorScheme.primary : colorScheme.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        StatusPill(label: badge, icon: badgeIcon, active: active),
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
    final colorScheme = Theme.of(context).colorScheme;
    final color = active ? AppColors.mint : AppColors.coral;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
