class AppEvent {
  const AppEvent({
    required this.type,
    required this.timestamp,
    this.id,
    this.source,
    this.user,
    this.detail,
  });

  final String? id;
  final String type;
  final DateTime timestamp;
  final String? source;
  final String? user;
  final String? detail;

  factory AppEvent.fromJson(Map<String, dynamic> json) {
    return AppEvent(
      id: json['id']?.toString(),
      type: json['type']?.toString() ?? 'unknown',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      source: json['source']?.toString(),
      user: json['user']?.toString(),
      detail: json['detail']?.toString(),
    );
  }
}
