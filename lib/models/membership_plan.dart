class MembershipPlan {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final String description;

  MembershipPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    this.description = '',
  });

  MembershipPlan copyWith({
    String? id,
    String? name,
    double? price,
    int? durationDays,
    String? description,
  }) {
    return MembershipPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      durationDays: durationDays ?? this.durationDays,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'description': description,
    };
  }

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      durationDays: json['durationDays'],
      description: json['description'] ?? '',
    );
  }

  // SQLite mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'description': description,
    };
  }

  factory MembershipPlan.fromMap(Map<String, dynamic> map) {
    return MembershipPlan(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      durationDays: map['durationDays'] as int,
      description: map['description'] ?? '',
    );
  }
}
