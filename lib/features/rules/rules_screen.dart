import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_design.dart';
import '../../core/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../models/minecraft_rule.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PageHeader(
            icon: Icons.rule_outlined,
            title: l10n.t('rules.title'),
            subtitle: l10n.t('rules.subtitle'),
            trailing: FilledButton.icon(
              onPressed: appState.isBusy
                  ? null
                  : () => _showRuleDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.t('rules.createCommand')),
            ),
          ),
          const SizedBox(height: 16),
          if (appState.rules.isEmpty)
            EmptyState(
              icon: Icons.auto_awesome_outlined,
              title: l10n.t('rules.empty'),
              message: l10n.t('rules.emptyHint'),
              action: FilledButton.icon(
                onPressed: appState.isBusy
                    ? null
                    : () => _showRuleDialog(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.t('rules.createCommand')),
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
    final l10n = context.l10n;
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
          l10n.t('rules.defaultUserSent', {'target': commandAction.visualName}),
    );
    final voiceMessageController = TextEditingController(
      text: rule?.voiceMessage.isNotEmpty == true
          ? rule!.voiceMessage
          : l10n.t('rules.defaultUserSent', {
              'target': commandAction.visualName,
            }),
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
              title: Text(
                isEditing
                    ? l10n.t('rules.editCommand')
                    : l10n.t('rules.createCommand'),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: eventType,
                        decoration: InputDecoration(
                          labelText: l10n.t('rules.tiktokEvent'),
                          prefixIcon: const Icon(Icons.bolt),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'gift',
                            child: Text(l10n.t('event.gift')),
                          ),
                          DropdownMenuItem(
                            value: 'like',
                            child: Text(l10n.t('event.likeReaction')),
                          ),
                          DropdownMenuItem(
                            value: 'follow',
                            child: Text(l10n.t('event.follow')),
                          ),
                          DropdownMenuItem(
                            value: 'member',
                            child: Text(l10n.t('event.liveEntry')),
                          ),
                          DropdownMenuItem(
                            value: 'share',
                            child: Text(l10n.t('event.share')),
                          ),
                          DropdownMenuItem(
                            value: 'chat',
                            child: Text(l10n.t('event.chat')),
                          ),
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
                          decoration: InputDecoration(
                            labelText: l10n.t('rules.giftType'),
                            prefixIcon: const Icon(Icons.card_giftcard),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            for (final gift in _giftOptions)
                              DropdownMenuItem(
                                value: gift,
                                child: Text(_giftOptionLabel(gift, l10n)),
                              ),
                            DropdownMenuItem(
                              value: _customGiftOption,
                              child: Text(l10n.t('common.other')),
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
                            decoration: InputDecoration(
                              labelText: l10n.t('rules.exactGiftName'),
                              hintText: 'Rose',
                              prefixIcon: const Icon(Icons.edit),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ] else
                        TextField(
                          controller: triggerController,
                          decoration: InputDecoration(
                            labelText: eventType == 'chat'
                                ? l10n.t('rules.exactChatMessage')
                                : l10n.t('rules.trigger'),
                            hintText: eventType == 'chat' ? 'hola' : 'Like',
                            prefixIcon: const Icon(Icons.card_giftcard),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<_CommandAction>(
                        initialValue: commandAction,
                        decoration: InputDecoration(
                          labelText: l10n.t('rules.minecraftAction'),
                          prefixIcon: const Icon(Icons.auto_awesome),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final action in _commandActions)
                            DropdownMenuItem(
                              value: action,
                              child: Text(_commandActionLabel(action, l10n)),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            commandAction = value;
                            announcementController.text = l10n.t(
                              'rules.defaultUserSent',
                              {'target': value.visualName},
                            );
                            if (!voiceEnabled ||
                                voiceMessageController.text.trim().isEmpty) {
                              voiceMessageController.text = l10n.t(
                                'rules.defaultUserSent',
                                {'target': value.visualName},
                              );
                            }
                            updateGeneratedCommand();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.badge_outlined),
                        title: Text(l10n.t('rules.showUserOnSpawn')),
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
                        title: Text(l10n.t('rules.announceCommandInChat')),
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
                          decoration: InputDecoration(
                            labelText: l10n.t('rules.announcementMessage'),
                            hintText: l10n.t('rules.userSentCreeperHint'),
                            prefixIcon: const Icon(Icons.chat_bubble_outline),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) =>
                              setDialogState(updateGeneratedCommand),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.volume_up_outlined),
                        title: Text(l10n.t('rules.readMessageWithVoice')),
                        value: voiceEnabled,
                        onChanged: (value) {
                          setDialogState(() {
                            voiceEnabled = value;
                            if (voiceMessageController.text.trim().isEmpty) {
                              voiceMessageController.text = l10n.t(
                                'rules.defaultUserSent',
                                {'target': commandAction.visualName},
                              );
                            }
                          });
                        },
                      ),
                      if (voiceEnabled) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: voiceMessageController,
                          decoration: InputDecoration(
                            labelText: l10n.t('rules.voiceText'),
                            hintText: l10n.t('rules.userSentCreeperHint'),
                            prefixIcon: const Icon(Icons.spatial_audio_off),
                            border: const OutlineInputBorder(),
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
                        decoration: InputDecoration(
                          labelText: l10n.t('rules.targetedTo'),
                          prefixIcon: const Icon(Icons.person_pin_circle),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final mode in _targetModes)
                            DropdownMenuItem(
                              value: mode,
                              child: Text(_targetModeLabel(mode, l10n)),
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
                          decoration: InputDecoration(
                            labelText: l10n.t('rules.minecraftPlayerName'),
                            hintText: 'Nivroy',
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) =>
                              setDialogState(updateGeneratedCommand),
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<_PositionOption>(
                        initialValue: position,
                        decoration: InputDecoration(
                          labelText: l10n.t('rules.positionRelativeToPlayer'),
                          prefixIcon: const Icon(Icons.explore),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final option in _positions)
                            DropdownMenuItem(
                              value: option,
                              child: Text(_positionOptionLabel(option, l10n)),
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
                        decoration: InputDecoration(
                          labelText: l10n.t('rules.visualName'),
                          hintText: 'Creeper',
                          prefixIcon: const Icon(Icons.label),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commandController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.t('rules.generatedCommand'),
                          prefixIcon: const Icon(Icons.terminal),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.t('common.cancel')),
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
                  label: Text(
                    isEditing ? l10n.t('common.update') : l10n.t('common.save'),
                  ),
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

String _giftOptionLabel(_GiftOption gift, AppLocalizations l10n) {
  if (gift.isCustom) {
    return l10n.t('common.other');
  }
  return switch (gift.trigger) {
    'Rose' => l10n.t('gift.rose'),
    'Doughnut' => l10n.t('gift.doughnut'),
    'GG' => 'GG',
    'Heart Me' => 'Heart Me',
    'TikTok' => 'TikTok',
    'Finger Heart' => 'Finger Heart',
    'Perfume' => l10n.t('gift.perfume'),
    'Cap' => l10n.t('gift.cap'),
    _ => gift.label,
  };
}

String _commandActionLabel(_CommandAction action, AppLocalizations l10n) {
  return switch (action.entity) {
    'minecraft:creeper' => l10n.t('action.spawnCreeper'),
    'minecraft:zombie' => l10n.t('action.spawnZombie'),
    'minecraft:skeleton' => l10n.t('action.spawnSkeleton'),
    'minecraft:tnt' => l10n.t('action.spawnTnt'),
    'minecraft:enderman' => l10n.t('action.spawnEnderman'),
    'minecraft:spider' => l10n.t('action.spawnSpider'),
    'minecraft:witch' => l10n.t('action.spawnWitch'),
    'minecraft:lightning_bolt' => l10n.t('action.summonLightning'),
    _ => action.label,
  };
}

String _targetModeLabel(_TargetMode mode, AppLocalizations l10n) {
  return switch (mode.value) {
    'all' => l10n.t('target.all'),
    'random' => l10n.t('target.random'),
    'player' => l10n.t('target.player'),
    _ => mode.label,
  };
}

String _positionOptionLabel(_PositionOption option, AppLocalizations l10n) {
  return switch (option.coordinates) {
    '~ ~ ~' => l10n.t('position.onPlayer'),
    '~ ~2 ~' => l10n.t('position.abovePlayer'),
    '~ ~-1 ~' => l10n.t('position.belowPlayer'),
    '^ ^ ^2' => l10n.t('position.inFrontOfPlayer'),
    '^ ^ ^-2' => l10n.t('position.behindPlayer'),
    '^-2 ^ ^' => l10n.t('position.left'),
    '^2 ^ ^' => l10n.t('position.right'),
    _ => option.label,
  };
}

String _armorSlotLabel(_ArmorSlot slot, AppLocalizations l10n) {
  return switch (slot.equipmentSlot) {
    'armor.head' => l10n.t('armor.helmet'),
    'armor.chest' => l10n.t('armor.chestplate'),
    'armor.legs' => l10n.t('armor.leggings'),
    'armor.feet' => l10n.t('armor.boots'),
    _ => slot.label,
  };
}

String _armorMaterialLabel(_ArmorMaterial material, AppLocalizations l10n) {
  return switch (material.value) {
    'golden' => l10n.t('armor.gold'),
    'diamond' => l10n.t('armor.diamond'),
    'iron' => l10n.t('armor.iron'),
    _ => material.label,
  };
}

String _weaponOptionLabel(_WeaponOption weapon, AppLocalizations l10n) {
  return switch (weapon.itemId) {
    'minecraft:iron_sword' => l10n.t('weapon.sword'),
    'minecraft:iron_axe' => l10n.t('weapon.axe'),
    _ => weapon.label,
  };
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
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.t('rules.armor'),
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
            child: Text(
              l10n.t('rules.weapon'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final weapon in _zombieWeapons)
                FilterChip(
                  label: Text(_weaponOptionLabel(weapon, l10n)),
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
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _armorSlotLabel(slot, l10n),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final material in _armorMaterials)
              FilterChip(
                label: Text(_armorMaterialLabel(material, l10n)),
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
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Opacity(
        opacity: rule.enabled ? 1 : 0.55,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rule.enabled
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  rule.enabled
                      ? Icons.auto_awesome
                      : Icons.auto_awesome_outlined,
                  color: rule.enabled
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          rule.trigger,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Chip(
                          label: Text(_eventTypeLabel(rule.eventType, l10n)),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (!rule.enabled)
                          Chip(
                            label: Text(l10n.t('status.off')),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (rule.voiceEnabled)
                          Chip(
                            avatar: const Icon(Icons.volume_up, size: 16),
                            label: Text(l10n.t('rules.voice')),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rule.target,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rule.command,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Switch(
                    value: rule.enabled,
                    onChanged: appState.isBusy
                        ? null
                        : (value) => appState.toggleRule(rule, value),
                  ),
                  IconButton(
                    tooltip: l10n.t('rules.editRule'),
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
                        ? l10n.t('rules.testCommand')
                        : l10n.t('rules.enableRuleToTest'),
                    onPressed: appState.isBusy || !rule.enabled
                        ? null
                        : () => appState.testRule(rule),
                    icon: const Icon(Icons.play_arrow),
                  ),
                  IconButton(
                    tooltip: l10n.t('rules.deleteRule'),
                    onPressed: appState.isBusy
                        ? null
                        : () => appState.deleteRule(rule),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
}
