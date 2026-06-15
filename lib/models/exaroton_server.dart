class ExarotonServer {
  const ExarotonServer({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
  });

  final String id;
  final String name;
  final String address;
  final int status;

  factory ExarotonServer.fromJson(Map<String, dynamic> json) {
    return ExarotonServer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Servidor Exaroton',
      address: json['address']?.toString() ?? '',
      status: int.tryParse(json['status']?.toString() ?? '') ?? 0,
    );
  }

  String get label {
    final suffix = address.isEmpty ? id : address;
    return '$name - $suffix';
  }
}
