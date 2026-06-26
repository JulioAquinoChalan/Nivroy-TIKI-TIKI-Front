import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_design.dart';
import '../../core/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../models/minecraft_rule.dart';
import '../../models/overlay_item.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          icon: Icons.settings_outlined,
          title: l10n.t('settings.title'),
          subtitle: l10n.t('settings.subtitle'),
          trailing: StatusPill(
            label: appState.authEmail.isEmpty
                ? l10n.t('settings.session')
                : appState.authEmail,
            icon: Icons.account_circle_outlined,
            active: appState.authEmail.isNotEmpty,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            children: [
              Row(
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
                    label: Text(l10n.t('common.logout')),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.language),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.t('settings.language'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: appState.languageCode,
                      decoration: InputDecoration(
                        labelText: l10n.t('settings.languageField'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'es',
                          child: Text(l10n.t('settings.languageSpanish')),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(l10n.t('settings.languageEnglish')),
                        ),
                      ],
                      onChanged: appState.isBusy
                          ? null
                          : (value) {
                              if (value != null) {
                                appState.setLanguageCode(value);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _OverlaySettingsCard(appState: appState),
      ],
    );
  }
}

class _OverlaySettingsCard extends StatefulWidget {
  const _OverlaySettingsCard({required this.appState});

  final AppState appState;

  @override
  State<_OverlaySettingsCard> createState() => _OverlaySettingsCardState();
}

class _OverlaySettingsCardState extends State<_OverlaySettingsCard> {
  OverlayPreviewKind? _visiblePreview;

  void _togglePreview(OverlayPreviewKind preview) {
    setState(() {
      _visiblePreview = _visiblePreview == preview ? null : preview;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final l10n = context.l10n;
    final overlays = [
      OverlayItem(
        title: l10n.t('settings.overlayAnnouncementsUrl'),
        url: appState.overlayAnnouncementsLiveStudioUrl,
        browserUrl: appState.overlayAnnouncementsUrl,
        copyTooltip: l10n.t('settings.copyAnnouncementsUrl'),
      ),
      OverlayItem(
        title: l10n.t('settings.overlayGiftsUrl'),
        url: appState.overlayLiveStudioUrl,
        browserUrl: appState.overlayRulesUrl,
        copyTooltip: l10n.t('settings.copyGiftsUrl'),
        preview: OverlayPreviewKind.gifts,
      ),
    ];

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.t('settings.overlayLiveStudio'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _OverlayUrlSection(
            overlay: overlays[0],
            previewVisible: false,
            onTogglePreview: _togglePreview,
          ),
          const SizedBox(height: 18),
          _OverlayUrlSection(
            overlay: overlays[1],
            previewVisible: _visiblePreview == overlays[1].preview,
            onTogglePreview: _togglePreview,
            preview: _OverlayPreview(rules: appState.rules),
          ),
        ],
      ),
    );
  }
}

class _OverlayUrlSection extends StatelessWidget {
  const _OverlayUrlSection({
    required this.overlay,
    required this.previewVisible,
    required this.onTogglePreview,
    this.preview,
  });

  final OverlayItem overlay;
  final bool previewVisible;
  final ValueChanged<OverlayPreviewKind> onTogglePreview;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final browserUrl = overlay.browserUrl;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                overlay.title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            if (overlay.preview != null)
              IconButton(
                tooltip: previewVisible
                    ? l10n.t('settings.hidePreview')
                    : l10n.t('settings.showPreview'),
                onPressed: () => onTogglePreview(overlay.preview!),
                icon: Icon(
                  previewVisible ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            IconButton(
              tooltip: overlay.copyTooltip,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: overlay.url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.t('settings.urlCopied'))),
                );
              },
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SelectableText(
          overlay.url,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (browserUrl != null && browserUrl != overlay.url) ...[
          const SizedBox(height: 10),
          Text(
            l10n.t('settings.browserAlternativeUrl'),
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
        if (previewVisible && preview != null) ...[
          const SizedBox(height: 12),
          preview!,
        ],
      ],
    );
  }
}

class _OverlayPreview extends StatelessWidget {
  const _OverlayPreview({required this.rules});

  final List<MinecraftRule> rules;

  @override
  Widget build(BuildContext context) {
    final previewRules = rules.where((rule) => rule.enabled).take(6).toList();
    final l10n = context.l10n;

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
                l10n.t('settings.preview'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFFB8C7C3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (previewRules.isEmpty)
            Text(l10n.t('settings.noActiveCommands'))
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
    final l10n = context.l10n;

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
                    _eventTypeLabel(rule.eventType, l10n),
                    style: const TextStyle(
                      color: Color(0xFF8BE8D3),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _instruction(rule, l10n),
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

  String _instruction(MinecraftRule rule, AppLocalizations l10n) {
    return switch (rule.eventType) {
      'chat' => l10n.t('settings.previewInstructionChat', {
        'trigger': rule.trigger,
      }),
      'like' => l10n.t('settings.previewInstructionLike'),
      'follow' => l10n.t('settings.previewInstructionFollow'),
      'member' => l10n.t('settings.previewInstructionMember'),
      'share' => l10n.t('settings.previewInstructionShare'),
      _ => l10n.t('settings.previewInstructionGift', {'trigger': rule.trigger}),
    };
  }

  String _eventTypeLabel(String eventType, AppLocalizations l10n) {
    return switch (eventType) {
      'gift' => l10n.t('event.gift'),
      'like' => l10n.t('event.like'),
      'follow' => l10n.t('event.follow'),
      'member' => l10n.t('event.member'),
      'share' => l10n.t('event.share'),
      'chat' => l10n.t('event.chat'),
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
