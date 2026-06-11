class MinecraftRule {
  const MinecraftRule({
    required this.id,
    required this.eventType,
    required this.trigger,
    required this.command,
    required this.target,
    required this.enabled,
  });

  final String id;
  final String eventType;
  final String trigger;
  final String command;
  final String target;
  final bool enabled;

  factory MinecraftRule.fromJson(Map<String, dynamic> json) {
    return MinecraftRule(
      id: json['id']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? 'gift',
      trigger: json['trigger']?.toString() ?? '',
      command: json['command']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      enabled: json['enabled'] != false,
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
    };
  }
}
