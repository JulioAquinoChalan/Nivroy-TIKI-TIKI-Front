import 'package:flutter/material.dart';

import '../../core/app_design.dart';
import '../../l10n/app_localizations.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tutorials.length, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    setState(() => _selectedIndex = _tabController.index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tutorial = _tutorials[_selectedIndex];
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          icon: Icons.school_outlined,
          title: l10n.t('tutorial.title'),
          subtitle: l10n.t('tutorial.subtitle'),
          trailing: StatusPill(
            label: l10n.t(tutorial.tabLabelKey),
            icon: tutorial.icon,
            active: true,
          ),
        ),
        const SizedBox(height: 16),
        Card(
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
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  indicatorSize: TabBarIndicatorSize.tab,
                  onTap: (value) => setState(() => _selectedIndex = value),
                  tabs: [
                    for (final item in _tutorials)
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.icon),
                            const SizedBox(width: 8),
                            Text(l10n.t(item.tabLabelKey)),
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
                  child: _TutorialGuideCard(
                    key: ValueKey(tutorial.tabLabelKey),
                    tutorial: tutorial,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TutorialGuideCard extends StatelessWidget {
  const _TutorialGuideCard({super.key, required this.tutorial});

  final _TutorialContent tutorial;

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
              Icon(tutorial.icon, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.t(tutorial.titleKey),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < tutorial.stepKeys.length; index++) ...[
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
                    child: Text(context.l10n.t(tutorial.stepKeys[index])),
                  ),
                ),
              ],
            ),
            if (index < tutorial.stepKeys.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TutorialContent {
  const _TutorialContent({
    required this.tabLabelKey,
    required this.titleKey,
    required this.icon,
    required this.stepKeys,
  });

  final String tabLabelKey;
  final String titleKey;
  final IconData icon;
  final List<String> stepKeys;
}

const _tutorials = [
  _TutorialContent(
    tabLabelKey: 'tutorial.tiktokTab',
    titleKey: 'tutorial.tiktokTitle',
    icon: Icons.live_tv,
    stepKeys: [
      'tutorial.tiktokStep1',
      'tutorial.tiktokStep2',
      'tutorial.tiktokStep3',
      'tutorial.tiktokStep4',
      'tutorial.tiktokStep5',
    ],
  ),
  _TutorialContent(
    tabLabelKey: 'tutorial.localTab',
    titleKey: 'tutorial.localTitle',
    icon: Icons.computer,
    stepKeys: [
      'tutorial.localStep1',
      'tutorial.localStep2',
      'tutorial.localStep3',
      'tutorial.localStep4',
      'tutorial.localStep5',
      'tutorial.localStep6',
    ],
  ),
  _TutorialContent(
    tabLabelKey: 'tutorial.exarotonTab',
    titleKey: 'tutorial.exarotonTitle',
    icon: Icons.cloud_outlined,
    stepKeys: [
      'tutorial.exarotonStep1',
      'tutorial.exarotonStep2',
      'tutorial.exarotonStep3',
      'tutorial.exarotonStep4',
      'tutorial.exarotonStep5',
      'tutorial.exarotonStep6',
      'tutorial.exarotonStep7',
    ],
  ),
];
