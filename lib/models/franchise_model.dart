class Franchise {
  final String id;
  final String name;
  final DateTime createdAt;
  final int balance;

  Franchise({
    required this.id,
    required this.name,
    required this.createdAt,
    this.balance = 0,
  });

  factory Franchise.fromMap(Map<String, dynamic> map) {
    return Franchise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      balance: map['balance'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'balance': balance,
    };
  }

  Franchise copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? balance,
  }) {
    return Franchise(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      balance: balance ?? this.balance,
    );}
}