class HealthStatus {
  const HealthStatus({
    required this.backendOnline,
    required this.tiktokConnected,
    required this.minecraftConnected,
    required this.currentTikTokUser,
    required this.minecraftHost,
    required this.minecraftPort,
  });

  final bool backendOnline;
  final bool tiktokConnected;
  final bool minecraftConnected;
  final String currentTikTokUser;
  final String minecraftHost;
  final int minecraftPort;

  factory HealthStatus.offline() {
    return const HealthStatus(
      backendOnline: false,
      tiktokConnected: false,
      minecraftConnected: false,
      currentTikTokUser: '',
      minecraftHost: '127.0.0.1',
      minecraftPort: 25575,
    );
  }

  factory HealthStatus.fromJson(
    Map<String, dynamic> json, {
    required bool backendOnline,
  }) {
    return HealthStatus(
      backendOnline: backendOnline,
      tiktokConnected: json['tiktokConnected'] == true,
      minecraftConnected: json['minecraftConnected'] == true,
      currentTikTokUser: json['currentTikTokUser']?.toString() ?? '',
      minecraftHost: json['minecraftHost']?.toString() ?? '127.0.0.1',
      minecraftPort:
          int.tryParse(json['minecraftPort']?.toString() ?? '') ?? 25575,
    );
  }
}
