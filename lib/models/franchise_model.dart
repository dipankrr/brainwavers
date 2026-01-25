class Franchise {
  final String id;
  final String name;
  final DateTime createdAt;

  Franchise({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Franchise.fromMap(Map<String, dynamic> map) {
    return Franchise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}