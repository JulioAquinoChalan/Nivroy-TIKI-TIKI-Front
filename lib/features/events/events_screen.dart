import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_design.dart';
import '../../core/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_event.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AppState>().events;
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          icon: Icons.bolt_outlined,
          title: l10n.t('events.title'),
          subtitle: l10n.t('events.subtitle'),
          trailing: StatusPill(
            label: l10n.t('events.liveFeed'),
            icon: Icons.sensors,
            active: events.isNotEmpty,
          ),
        ),
        const SizedBox(height: 16),
        if (events.isEmpty)
          EmptyState(
            icon: Icons.timeline_outlined,
            title: l10n.t('events.empty'),
            message: l10n.t('events.emptyHint'),
          )
        else
          for (final event in events) ...[
            _EventTile(event: event),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final AppEvent event;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.type.characters.first.toUpperCase(),
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.type,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (event.user != null) '@${event.user}',
                      if (event.detail != null) event.detail,
                    ].join(' - '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              TimeOfDay.fromDateTime(event.timestamp.toLocal()).format(context),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
