import 'package:flutter/material.dart';

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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tutorial', style: Theme.of(context).textTheme.headlineMedium),
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
                            Text(item.tabLabel),
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
                    key: ValueKey(tutorial.tabLabel),
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
                  tutorial.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < tutorial.steps.length; index++) ...[
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
                    child: Text(tutorial.steps[index]),
                  ),
                ),
              ],
            ),
            if (index < tutorial.steps.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TutorialContent {
  const _TutorialContent({
    required this.tabLabel,
    required this.title,
    required this.icon,
    required this.steps,
  });

  final String tabLabel;
  final String title;
  final IconData icon;
  final List<String> steps;
}

const _tutorials = [
  _TutorialContent(
    tabLabel: 'TikTok',
    title: 'Guia rapida para conectar TikTok Live',
    icon: Icons.live_tv,
    steps: [
      'Abre el Dashboard y ubica la tarjeta Conexion TikTok Live.',
      'Escribe tu usuario de TikTok sin arroba.',
      'Presiona Conectar TikTok.',
      'Inicia o mantén activo tu Live de TikTok.',
      'Verifica que el estado cambie a Conectado antes de crear reglas.',
    ],
  ),
  _TutorialContent(
    tabLabel: 'Minecraft local',
    title: 'Guia rapida para conectar Minecraft local',
    icon: Icons.computer,
    steps: [
      'Instala Paper/Bukkit en tu servidor local de Minecraft.',
      'Instala el plugin ServerTap en la carpeta plugins del servidor.',
      'Inicia o reinicia el servidor para que ServerTap genere su configuracion.',
      'Copia la API key de ServerTap y confirma el puerto configurado.',
      'En el Dashboard, pega la IP local, el puerto y la API key.',
      'Presiona Conectar local y verifica que Minecraft quede conectado.',
    ],
  ),
  _TutorialContent(
    tabLabel: 'Minecraft Exaroton',
    title: 'Guia rapida para Exaroton',
    icon: Icons.cloud_outlined,
    steps: [
      'Crea tu servidor de Minecraft en Exaroton.',
      'Cambia el software del servidor a Paper/Bukkit.',
      'En el apartado de plugins, busca ServerTap e instalalo.',
      'Obtén tu token API desde Cuenta > Ajustes. Si no tienes uno, genera un token nuevo.',
      'Pega tu token API en el Dashboard y carga tus servidores.',
      'Selecciona tu servidor y conectalo a Exaroton.',
      'Crea tus reglas para empezar a reaccionar con los usuarios :D',
    ],
  ),
];
