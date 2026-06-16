import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/minecraft_rule.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appState.authEmail,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: appState.isBusy ? null : appState.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Salir'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _OverlaySettingsCard(appState: appState),
      ],
    );
  }
}

class _OverlaySettingsCard extends StatelessWidget {
  const _OverlaySettingsCard({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final liveStudioUrl = appState.overlayLiveStudioUrl;
    final browserUrl = appState.overlayRulesUrl;
    final announcementsLiveStudioUrl =
        appState.overlayAnnouncementsLiveStudioUrl;
    final announcementsBrowserUrl = appState.overlayAnnouncementsUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Overlay Live Studio',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar URL de comandos',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: liveStudioUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copiada')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'URL recomendada para TikTok Live Studio',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            SelectableText(
              liveStudioUrl,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (browserUrl != liveStudioUrl) ...[
              const SizedBox(height: 10),
              Text(
                'URL alternativa para navegador',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              SelectableText(
                browserUrl,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'URL para anuncios de 3 segundos',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar URL de anuncios',
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: announcementsLiveStudioUrl),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copiada')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              announcementsLiveStudioUrl,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (announcementsBrowserUrl != announcementsLiveStudioUrl) ...[
              const SizedBox(height: 10),
              Text(
                'URL alternativa para navegador',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              SelectableText(
                announcementsBrowserUrl,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _OverlayPreview(rules: appState.rules),
          ],
        ),
      ),
    );
  }
}

class _OverlayPreview extends StatelessWidget {
  const _OverlayPreview({required this.rules});

  final List<MinecraftRule> rules;

  @override
  Widget build(BuildContext context) {
    final previewRules = rules.where((rule) => rule.enabled).take(6).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xB3111214),
        border: Border.all(color: const Color(0x668BE8D3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nivroy TIKI-TIKI',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Vista previa',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFFB8C7C3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (previewRules.isEmpty)
            const Text('No hay comandos activos.')
          else
            Column(
              children: [
                for (final rule in previewRules) ...[
                  _OverlayRuleTile(rule: rule),
                  if (rule != previewRules.last) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _OverlayRuleTile extends StatelessWidget {
  const _OverlayRuleTile({required this.rule});

  final MinecraftRule rule;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xDD181B1F),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x248BE8D3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _eventShortLabel(rule.eventType),
              style: const TextStyle(
                color: Color(0xFF8BE8D3),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x668BE8D3)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _eventTypeLabel(rule.eventType),
                    style: const TextStyle(
                      color: Color(0xFF8BE8D3),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _instruction(rule),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '-> ${rule.target}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _instruction(MinecraftRule rule) {
    return switch (rule.eventType) {
      'chat' => 'Escribe ${rule.trigger}',
      'like' => 'Toca like',
      'follow' => 'Sigue el live',
      'member' => 'Entra al live',
      'share' => 'Comparte el live',
      _ => 'Envia ${rule.trigger}',
    };
  }

  String _eventTypeLabel(String eventType) {
    return switch (eventType) {
      'gift' => 'Regalo',
      'like' => 'Like',
      'follow' => 'Follow',
      'member' => 'Entrada',
      'share' => 'Share',
      'chat' => 'Chat',
      _ => eventType,
    };
  }

  String _eventShortLabel(String eventType) {
    return switch (eventType) {
      'gift' => 'GIFT',
      'like' => 'LIKE',
      'follow' => 'FOL',
      'member' => 'JOIN',
      'share' => 'SHR',
      'chat' => 'CHAT',
      _ => 'CMD',
    };
  }
}
