class Member {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String membershipPlanId;
  final DateTime joinDate;
  final DateTime? expiryDate;
  final bool isActive;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.membershipPlanId,
    required this.joinDate,
    this.expiryDate,
    this.isActive = true,
  });

  Member copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? membershipPlanId,
    DateTime? joinDate,
    DateTime? expiryDate,
    bool? isActive,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      membershipPlanId: membershipPlanId ?? this.membershipPlanId,
      joinDate: joinDate ?? this.joinDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'membershipPlanId': membershipPlanId,
      'joinDate': joinDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      membershipPlanId: json['membershipPlanId'],
      joinDate: DateTime.parse(json['joinDate']),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  // SQLite mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'membershipPlanId': membershipPlanId,
      'joinDate': joinDate.millisecondsSinceEpoch,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      membershipPlanId: map['membershipPlanId'],
      joinDate: DateTime.fromMillisecondsSinceEpoch(map['joinDate'] as int),
      expiryDate: map['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'] as int)
          : null,
      isActive: (map['isActive'] ?? 1) == 1,
    );
  }

  /// Number of whole days left until expiry. Negative means already expired. Null if no expiry.
  int? get daysLeft {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    return expiryDate!.difference(now).inDays;
  }

  /// Whether membership is expired as of now.
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());
}
