import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/minecraft_rule.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Rules',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: appState.isBusy
                    ? null
                    : () => _showRuleDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Crear comando'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (appState.rules.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No hay reglas configuradas'),
              ),
            )
          else
            for (final rule in appState.rules) ...[
              _RuleCard(rule: rule),
              const SizedBox(height: 12),
            ],
          if (appState.lastError != null) ...[
            const SizedBox(height: 4),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(appState.lastError!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showRuleDialog(
    BuildContext context, {
    MinecraftRule? rule,
  }) async {
    final isEditing = rule != null;
    var eventType = rule?.eventType ?? 'gift';
    var commandAction = _commandActions.first;
    var targetMode = _targetModes.first;
    var position = _positions.first;
    var showUserNameOnSpawn = rule?.command.contains('CustomName') ?? false;
    var announceCommand =
        rule?.command.split('\n').any((line) => line.contains(' run say ')) ??
        false;
    var voiceEnabled = rule?.voiceEnabled ?? false;
    var selectedGiftOption = _giftOptionForTrigger(
      rule?.trigger ?? _giftOptions.first.trigger,
    );
    final armorSelections = {
      for (final slot in _armorSlots) slot: null as _ArmorMaterial?,
    };
    _WeaponOption? zombieWeapon;
    final triggerController = TextEditingController(
      text: rule?.trigger ?? _giftOptions.first.trigger,
    );
    final targetController = TextEditingController(text: rule?.target ?? '');
    final playerController = TextEditingController();
    final announcementController = TextEditingController(
      text:
          _announcementFromCommand(rule?.command ?? '') ??
          '{user} envio un ${commandAction.visualName}',
    );
    final voiceMessageController = TextEditingController(
      text: rule?.voiceMessage.isNotEmpty == true
          ? rule!.voiceMessage
          : '{user} envio un ${commandAction.visualName}',
    );
    final commandController = TextEditingController(text: rule?.command ?? '');

    void updateGeneratedCommand() {
      final selector = switch (targetMode.value) {
        'all' => '@a',
        'random' => '@r',
        'player' =>
          playerController.text.trim().isEmpty
              ? '@p'
              : playerController.text.trim(),
        _ => '@a',
      };
      commandController.text = commandAction.buildCommand(
        selector,
        position.coordinates,
        equipment: _EquipmentOptions(
          armor: commandAction.supportsArmor
              ? Map<_ArmorSlot, _ArmorMaterial?>.from(armorSelections)
              : const {},
          mainHand: commandAction.supportsZombieWeapon ? zombieWeapon : null,
        ),
        spawnOptions: _SpawnOptions(
          customName: showUserNameOnSpawn ? '{user}' : '',
          announcementCommand: announceCommand
              ? announcementController.text.trim()
              : '',
        ),
      );
      targetController.text = commandAction.visualName;
    }

    if (!isEditing) {
      updateGeneratedCommand();
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar comando' : 'Crear comando'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: eventType,
                        decoration: const InputDecoration(
                          labelText: 'Evento TikTok',
                          prefixIcon: Icon(Icons.bolt),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'gift',
                            child: Text('Regalo'),
                          ),
                          DropdownMenuItem(
                            value: 'like',
                            child: Text('Reaccion Like'),
                          ),
                          DropdownMenuItem(
                            value: 'follow',
                            child: Text('Follow'),
                          ),
                          DropdownMenuItem(
                            value: 'member',
                            child: Text('Entrada al Live'),
                          ),
                          DropdownMenuItem(
                            value: 'share',
                            child: Text('Share'),
                          ),
                          DropdownMenuItem(value: 'chat', child: Text('Chat')),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            eventType = value;
                            if (value == 'gift') {
                              selectedGiftOption = _giftOptionForTrigger(
                                triggerController.text,
                              );
                              if (_nonGiftTriggers.contains(
                                triggerController.text,
                              )) {
                                selectedGiftOption = _giftOptions.first;
                                triggerController.text =
                                    selectedGiftOption.trigger;
                              }
                              return;
                            }

                            triggerController.text = switch (value) {
                              'like' => 'Like',
                              'follow' => 'Follow',
                              'member' => 'Member',
                              'share' => 'Share',
                              _ => triggerController.text,
                            };
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (eventType == 'gift') ...[
                        DropdownButtonFormField<_GiftOption>(
                          key: ValueKey(selectedGiftOption.trigger),
                          initialValue: selectedGiftOption,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de regalo',
                            prefixIcon: Icon(Icons.card_giftcard),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final gift in _giftOptions)
                              DropdownMenuItem(
                                value: gift,
                                child: Text(gift.label),
                              ),
                            const DropdownMenuItem(
                              value: _customGiftOption,
                              child: Text('Otro'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setDialogState(() {
                              selectedGiftOption = value;
                              if (!value.isCustom) {
                                triggerController.text = value.trigger;
                              }
                            });
                          },
                        ),
                        if (selectedGiftOption.isCustom) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: triggerController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre exacto del regalo',
                              hintText: 'Rose',
                              prefixIcon: Icon(Icons.edit),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ] else
                        TextField(
                          controller: triggerController,
                          decoration: InputDecoration(
                            labelText: eventType == 'chat'
                                ? 'Mensaje exacto del chat'
                                : 'Trigger',
                            hintText: eventType == 'chat' ? 'hola' : 'Like',
                            prefixIcon: const Icon(Icons.card_giftcard),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<_CommandAction>(
                        initialValue: commandAction,
                        decoration: const InputDecoration(
                          labelText: 'Accion Minecraft',
                          prefixIcon: Icon(Icons.auto_awesome),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final action in _commandActions)
                            DropdownMenuItem(
                              value: action,
                              child: Text(action.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            commandAction = value;
                            announcementController.text =
                                '{user} envio un ${value.visualName}';
                            if (!voiceEnabled ||
                                voiceMessageController.text.trim().isEmpty) {
                              voiceMessageController.text =
                                  '{user} envio un ${value.visualName}';
                            }
                            updateGeneratedCommand();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.badge_outlined),
                        title: const Text('Mostrar usuario en el spawn'),
                        value: showUserNameOnSpawn,
                        onChanged: (value) {
                          setDialogState(() {
                            showUserNameOnSpawn = value;
                            updateGeneratedCommand();
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.record_voice_over),
                        title: const Text('Anunciar comando en chat'),
                        value: announceCommand,
                        onChanged: (value) {
                          setDialogState(() {
                            announceCommand = value;
                            updateGeneratedCommand();
                          });
                        },
                      ),
                      if (announceCommand) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: announcementController,
                          decoration: const InputDecoration(
                            labelText: 'Mensaje del anuncio',
                            hintText: '{user} envio un creeper',
                            prefixIcon: Icon(Icons.chat_bubble_outline),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) =>
                              setDialogState(updateGeneratedCommand),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.volume_up_outlined),
                        title: const Text('Leer mensaje con voz'),
                        value: voiceEnabled,
                        onChanged: (value) {
                          setDialogState(() {
                            voiceEnabled = value;
                            if (voiceMessageController.text.trim().isEmpty) {
                              voiceMessageController.text =
                                  '{user} envio un ${commandAction.visualName}';
                            }
                          });
                        },
                      ),
                      if (voiceEnabled) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: voiceMessageController,
                          decoration: const InputDecoration(
                            labelText: 'Texto para voz',
                            hintText: '{user} envio un creeper',
                            prefixIcon: Icon(Icons.spatial_audio_off),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (commandAction.supportsArmor) ...[
                        const SizedBox(height: 12),
                        _EquipmentSection(
                          armorSelections: armorSelections,
                          zombieWeapon: commandAction.supportsZombieWeapon
                              ? zombieWeapon
                              : null,
                          showZombieWeapon: commandAction.supportsZombieWeapon,
                          onArmorChanged: (slot, material, selected) {
                            setDialogState(() {
                              armorSelections[slot] = selected
                                  ? material
                                  : null;
                              updateGeneratedCommand();
                            });
                          },
                          onZombieWeaponChanged: (weapon, selected) {
                            setDialogState(() {
                              zombieWeapon = selected ? weapon : null;
                              updateGeneratedCommand();
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<_TargetMode>(
                        initialValue: targetMode,
                        decoration: const InputDecoration(
                          labelText: 'Dirigido a',
                          prefixIcon: Icon(Icons.person_pin_circle),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final mode in _targetModes)
                            DropdownMenuItem(
                              value: mode,
                              child: Text(mode.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            targetMode = value;
                            updateGeneratedCommand();
                          });
                        },
                      ),
                      if (targetMode.value == 'player') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: playerController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del jugador Minecraft',
                            hintText: 'Nivroy',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) =>
                              setDialogState(updateGeneratedCommand),
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<_PositionOption>(
                        initialValue: position,
                        decoration: const InputDecoration(
                          labelText: 'Posicion respecto al jugador',
                          prefixIcon: Icon(Icons.explore),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final option in _positions)
                            DropdownMenuItem(
                              value: option,
                              child: Text(option.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            position = value;
                            updateGeneratedCommand();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: targetController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre visual',
                          hintText: 'Creeper',
                          prefixIcon: Icon(Icons.label),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commandController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Comando generado',
                          prefixIcon: Icon(Icons.terminal),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    if (isEditing) {
                      context.read<AppState>().updateRule(
                        id: rule.id,
                        eventType: eventType,
                        trigger: triggerController.text,
                        target: targetController.text,
                        command: commandController.text,
                        voiceEnabled: voiceEnabled,
                        voiceMessage: voiceMessageController.text,
                        enabled: rule.enabled,
                      );
                    } else {
                      context.read<AppState>().createRule(
                        eventType: eventType,
                        trigger: triggerController.text,
                        target: targetController.text,
                        command: commandController.text,
                        voiceEnabled: voiceEnabled,
                        voiceMessage: voiceMessageController.text,
                        enabled: true,
                      );
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? 'Actualizar' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    triggerController.dispose();
    targetController.dispose();
    playerController.dispose();
    announcementController.dispose();
    voiceMessageController.dispose();
    commandController.dispose();
  }
}

const _giftOptions = [
  _GiftOption(label: 'Rosa', trigger: 'Rose'),
  _GiftOption(label: 'Dona', trigger: 'Doughnut'),
  _GiftOption(label: 'GG', trigger: 'GG'),
  _GiftOption(label: 'Heart Me', trigger: 'Heart Me'),
  _GiftOption(label: 'TikTok', trigger: 'TikTok'),
  _GiftOption(label: 'Finger Heart', trigger: 'Finger Heart'),
  _GiftOption(label: 'Perfume', trigger: 'Perfume'),
  _GiftOption(label: 'Cap', trigger: 'Cap'),
];

const _customGiftOption = _GiftOption(
  label: 'Otro',
  trigger: '__custom_gift__',
  isCustom: true,
);

const _nonGiftTriggers = {'Like', 'Follow', 'Member', 'Share'};

_GiftOption _giftOptionForTrigger(String trigger) {
  final normalizedTrigger = trigger.trim().toLowerCase();
  for (final gift in _giftOptions) {
    if (gift.trigger.toLowerCase() == normalizedTrigger) {
      return gift;
    }
  }
  return _customGiftOption;
}

String? _announcementFromCommand(String command) {
  for (final line in command.split('\n')) {
    final marker = ' run say ';
    final markerIndex = line.indexOf(marker);
    if (markerIndex >= 0) {
      return line.substring(markerIndex + marker.length).trim();
    }
  }
  return null;
}

class _GiftOption {
  const _GiftOption({
    required this.label,
    required this.trigger,
    this.isCustom = false,
  });

  final String label;
  final String trigger;
  final bool isCustom;

  @override
  bool operator ==(Object other) {
    return other is _GiftOption &&
        other.label == label &&
        other.trigger == trigger &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode => Object.hash(label, trigger, isCustom);
}

const _commandActions = [
  _CommandAction(
    label: 'Spawnear Creeper',
    entity: 'minecraft:creeper',
    visualName: 'Creeper',
  ),
  _CommandAction(
    label: 'Spawnear Zombie',
    entity: 'minecraft:zombie',
    visualName: 'Zombie',
  ),
  _CommandAction(
    label: 'Spawnear Esqueleto',
    entity: 'minecraft:skeleton',
    visualName: 'Skeleton',
  ),
  _CommandAction(
    label: 'Spawnear TNT activa',
    entity: 'minecraft:tnt',
    visualName: 'TNT',
    nbt: '{Fuse:40}',
  ),
  _CommandAction(
    label: 'Spawnear Enderman',
    entity: 'minecraft:enderman',
    visualName: 'Enderman',
  ),
  _CommandAction(
    label: 'Spawnear Araña',
    entity: 'minecraft:spider',
    visualName: 'Spider',
  ),
  _CommandAction(
    label: 'Spawnear Bruja',
    entity: 'minecraft:witch',
    visualName: 'Witch',
  ),
  _CommandAction(
    label: 'Invocar Rayo',
    entity: 'minecraft:lightning_bolt',
    visualName: 'Lightning',
  ),
];

const _targetModes = [
  _TargetMode(value: 'all', label: 'Todos'),
  _TargetMode(value: 'random', label: 'Random'),
  _TargetMode(value: 'player', label: 'Jugador especifico'),
];

const _positions = [
  _PositionOption(label: 'En el jugador', coordinates: '~ ~ ~'),
  _PositionOption(label: 'Encima del jugador', coordinates: '~ ~2 ~'),
  _PositionOption(label: 'Debajo del jugador', coordinates: '~ ~-1 ~'),
  _PositionOption(label: 'Frente al jugador', coordinates: '^ ^ ^2'),
  _PositionOption(label: 'Detras del jugador', coordinates: '^ ^ ^-2'),
  _PositionOption(label: 'A la izquierda', coordinates: '^-2 ^ ^'),
  _PositionOption(label: 'A la derecha', coordinates: '^2 ^ ^'),
];

class _CommandAction {
  const _CommandAction({
    required this.label,
    required this.entity,
    required this.visualName,
    this.nbt = '',
  });

  final String label;
  final String entity;
  final String visualName;
  final String nbt;

  bool get supportsArmor =>
      entity == 'minecraft:zombie' || entity == 'minecraft:skeleton';

  bool get supportsZombieWeapon => entity == 'minecraft:zombie';

  String buildCommand(
    String selector,
    String coordinates, {
    _EquipmentOptions equipment = const _EquipmentOptions(),
    _SpawnOptions spawnOptions = const _SpawnOptions(),
  }) {
    final commandLines = <String>[
      if (spawnOptions.announcementCommand.isNotEmpty)
        'execute as $selector at @s run say ${spawnOptions.announcementCommand}',
    ];
    final spawnNbt = spawnOptions.toNbt();

    if (equipment.hasEquipment && supportsArmor) {
      commandLines.add(
        equipment.buildEquippedMobCommand(
          selector: selector,
          coordinates: coordinates,
          entity: entity,
          spawnNbt: spawnNbt,
        ),
      );
      return commandLines.join('\n');
    }

    final mergedNbt = _mergeNbt(_mergeNbt(nbt, equipment.toNbt()), spawnNbt);
    commandLines.add(
      'execute as $selector at @s run summon $entity $coordinates${mergedNbt.isEmpty ? '' : ' $mergedNbt'}',
    );
    return commandLines.join('\n');
  }

  String _mergeNbt(String baseNbt, String equipmentNbt) {
    if (baseNbt.isEmpty) {
      return equipmentNbt;
    }
    if (equipmentNbt.isEmpty) {
      return baseNbt;
    }

    return '${baseNbt.substring(0, baseNbt.length - 1)},${equipmentNbt.substring(1)}';
  }
}

class _SpawnOptions {
  const _SpawnOptions({this.customName = '', this.announcementCommand = ''});

  final String customName;
  final String announcementCommand;

  String toNbt() {
    final name = customName.trim();
    if (name.isEmpty) {
      return '';
    }

    final escapedName = name
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll("'", r"\'");
    return "{CustomName:'{\"text\":\"$escapedName\"}',CustomNameVisible:1b}";
  }
}

class _EquipmentOptions {
  const _EquipmentOptions({this.armor = const {}, this.mainHand});

  final Map<_ArmorSlot, _ArmorMaterial?> armor;
  final _WeaponOption? mainHand;

  bool get hasEquipment =>
      mainHand != null || armor.values.any((material) => material != null);

  String buildEquippedMobCommand({
    required String selector,
    required String coordinates,
    required String entity,
    String spawnNbt = '',
  }) {
    const tag = 'nivroy_equipped_spawn';
    final target =
        '@e[type=$entity,tag=$tag,sort=nearest,limit=1,distance=..8]';
    final summonNbt = _mergeSummonNbt('{Tags:["$tag"]}', spawnNbt);
    final commands = <String>[
      'execute as $selector at @s run summon $entity $coordinates $summonNbt',
    ];

    for (final slot in _armorSlots) {
      final material = armor[slot];
      if (material == null) {
        continue;
      }

      commands.add(
        'execute as $selector at @s run item replace entity $target ${slot.equipmentSlot} with minecraft:${material.value}_${slot.itemSuffix}',
      );
    }

    if (mainHand != null) {
      commands.add(
        'execute as $selector at @s run item replace entity $target weapon.mainhand with ${mainHand!.itemId}',
      );
    }

    commands.add('execute as $selector at @s run tag $target remove $tag');
    return commands.join('\n');
  }

  String toNbt() {
    final parts = <String>[];
    final armorItems = _armorItemNbt();
    if (armorItems != null) {
      parts.add('ArmorItems:$armorItems');
    }
    if (mainHand != null) {
      parts.add('HandItems:[${_itemNbt(mainHand!.itemId)},{}]');
    }

    return parts.isEmpty ? '' : '{${parts.join(',')}}';
  }

  String? _armorItemNbt() {
    final items = [
      for (final slot in _minecraftArmorOrder)
        armor[slot] == null
            ? '{}'
            : _itemNbt('minecraft:${armor[slot]!.value}_${slot.itemSuffix}'),
    ];

    if (items.every((item) => item == '{}')) {
      return null;
    }

    return '[${items.join(',')}]';
  }

  String _itemNbt(String itemId) {
    return '{id:"$itemId",count:1}';
  }

  String _mergeSummonNbt(String baseNbt, String spawnNbt) {
    if (spawnNbt.isEmpty) {
      return baseNbt;
    }

    return '${baseNbt.substring(0, baseNbt.length - 1)},${spawnNbt.substring(1)}';
  }
}

class _EquipmentSection extends StatelessWidget {
  const _EquipmentSection({
    required this.armorSelections,
    required this.zombieWeapon,
    required this.showZombieWeapon,
    required this.onArmorChanged,
    required this.onZombieWeaponChanged,
  });

  final Map<_ArmorSlot, _ArmorMaterial?> armorSelections;
  final _WeaponOption? zombieWeapon;
  final bool showZombieWeapon;
  final void Function(_ArmorSlot slot, _ArmorMaterial material, bool selected)
  onArmorChanged;
  final void Function(_WeaponOption weapon, bool selected)
  onZombieWeaponChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Armadura',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        for (final slot in _armorSlots) ...[
          _ArmorSlotSelector(
            slot: slot,
            selectedMaterial: armorSelections[slot],
            onChanged: onArmorChanged,
          ),
          const SizedBox(height: 8),
        ],
        if (showZombieWeapon) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Arma', style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final weapon in _zombieWeapons)
                FilterChip(
                  label: Text(weapon.label),
                  selected: zombieWeapon == weapon,
                  onSelected: (selected) =>
                      onZombieWeaponChanged(weapon, selected),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ArmorSlotSelector extends StatelessWidget {
  const _ArmorSlotSelector({
    required this.slot,
    required this.selectedMaterial,
    required this.onChanged,
  });

  final _ArmorSlot slot;
  final _ArmorMaterial? selectedMaterial;
  final void Function(_ArmorSlot slot, _ArmorMaterial material, bool selected)
  onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(slot.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final material in _armorMaterials)
              FilterChip(
                label: Text(material.label),
                selected: selectedMaterial == material,
                onSelected: (selected) => onChanged(slot, material, selected),
              ),
          ],
        ),
      ],
    );
  }
}

const _armorSlots = [
  _ArmorSlot(label: 'Casco', itemSuffix: 'helmet', equipmentSlot: 'armor.head'),
  _ArmorSlot(
    label: 'Pechera',
    itemSuffix: 'chestplate',
    equipmentSlot: 'armor.chest',
  ),
  _ArmorSlot(
    label: 'Pantalon',
    itemSuffix: 'leggings',
    equipmentSlot: 'armor.legs',
  ),
  _ArmorSlot(label: 'Botas', itemSuffix: 'boots', equipmentSlot: 'armor.feet'),
];

const _minecraftArmorOrder = [
  _ArmorSlot(label: 'Botas', itemSuffix: 'boots', equipmentSlot: 'armor.feet'),
  _ArmorSlot(
    label: 'Pantalon',
    itemSuffix: 'leggings',
    equipmentSlot: 'armor.legs',
  ),
  _ArmorSlot(
    label: 'Pechera',
    itemSuffix: 'chestplate',
    equipmentSlot: 'armor.chest',
  ),
  _ArmorSlot(label: 'Casco', itemSuffix: 'helmet', equipmentSlot: 'armor.head'),
];

const _armorMaterials = [
  _ArmorMaterial(label: 'Oro', value: 'golden'),
  _ArmorMaterial(label: 'Diamante', value: 'diamond'),
  _ArmorMaterial(label: 'Hierro', value: 'iron'),
];

const _zombieWeapons = [
  _WeaponOption(label: 'Espada', itemId: 'minecraft:iron_sword'),
  _WeaponOption(label: 'Hacha', itemId: 'minecraft:iron_axe'),
];

class _ArmorSlot {
  const _ArmorSlot({
    required this.label,
    required this.itemSuffix,
    required this.equipmentSlot,
  });

  final String label;
  final String itemSuffix;
  final String equipmentSlot;

  @override
  bool operator ==(Object other) {
    return other is _ArmorSlot &&
        other.label == label &&
        other.itemSuffix == itemSuffix &&
        other.equipmentSlot == equipmentSlot;
  }

  @override
  int get hashCode => Object.hash(label, itemSuffix, equipmentSlot);
}

class _ArmorMaterial {
  const _ArmorMaterial({required this.label, required this.value});

  final String label;
  final String value;

  @override
  bool operator ==(Object other) {
    return other is _ArmorMaterial &&
        other.label == label &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(label, value);
}

class _WeaponOption {
  const _WeaponOption({required this.label, required this.itemId});

  final String label;
  final String itemId;

  @override
  bool operator ==(Object other) {
    return other is _WeaponOption &&
        other.label == label &&
        other.itemId == itemId;
  }

  @override
  int get hashCode => Object.hash(label, itemId);
}

class _TargetMode {
  const _TargetMode({required this.value, required this.label});

  final String value;
  final String label;
}

class _PositionOption {
  const _PositionOption({required this.label, required this.coordinates});

  final String label;
  final String coordinates;
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule});

  final MinecraftRule rule;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Card(
      child: Opacity(
        opacity: rule.enabled ? 1 : 0.55,
        child: ListTile(
          leading: Icon(
            rule.enabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
          ),
          title: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(rule.trigger),
              Chip(
                label: Text(_eventTypeLabel(rule.eventType)),
                visualDensity: VisualDensity.compact,
              ),
              if (!rule.enabled)
                const Chip(
                  label: Text('Apagado'),
                  visualDensity: VisualDensity.compact,
                ),
              if (rule.voiceEnabled)
                const Chip(
                  avatar: Icon(Icons.volume_up, size: 16),
                  label: Text('Voz'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          subtitle: Text(rule.command),
          trailing: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(rule.target),
              Switch(
                value: rule.enabled,
                onChanged: appState.isBusy
                    ? null
                    : (value) => appState.toggleRule(rule, value),
              ),
              IconButton(
                tooltip: 'Editar regla',
                onPressed: appState.isBusy
                    ? null
                    : () => const RulesScreen()._showRuleDialog(
                        context,
                        rule: rule,
                      ),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: rule.enabled
                    ? 'Probar comando'
                    : 'Activa la regla para probarla',
                onPressed: appState.isBusy || !rule.enabled
                    ? null
                    : () => appState.testRule(rule),
                icon: const Icon(Icons.play_arrow),
              ),
              IconButton(
                tooltip: 'Eliminar regla',
                onPressed: appState.isBusy
                    ? null
                    : () => appState.deleteRule(rule),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
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
}
