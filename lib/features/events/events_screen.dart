import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_event.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AppState>().events;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.t('events.title'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? Center(child: Text(l10n.t('events.empty')))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: events.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _EventTile(event: events[index]),
                ),
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final AppEvent event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(event.type.characters.first.toUpperCase()),
        ),
        title: Text(event.type),
        subtitle: Text(
          [
            if (event.user != null) '@${event.user}',
            if (event.detail != null) event.detail,
          ].join(' - '),
        ),
        trailing: Text(
          TimeOfDay.fromDateTime(event.timestamp.toLocal()).format(context),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
