class MinecraftRule {
  const MinecraftRule({
    required this.id,
    required this.eventType,
    required this.trigger,
    required this.command,
    required this.target,
    required this.enabled,
    required this.voiceEnabled,
    required this.voiceMessage,
  });

  final String id;
  final String eventType;
  final String trigger;
  final String command;
  final String target;
  final bool enabled;
  final bool voiceEnabled;
  final String voiceMessage;

  factory MinecraftRule.fromJson(Map<String, dynamic> json) {
    return MinecraftRule(
      id: json['id']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? 'gift',
      trigger: json['trigger']?.toString() ?? '',
      command: json['command']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      enabled: json['enabled'] != false,
      voiceEnabled: json['voiceEnabled'] == true,
      voiceMessage: json['voiceMessage']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventType': eventType,
      'trigger': trigger,
      'command': command,
      'target': target,
      'enabled': enabled,
      'voiceEnabled': voiceEnabled,
      'voiceMessage': voiceMessage,
    };
  }
}
