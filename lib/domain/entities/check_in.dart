class CheckIn {
  final String id;
  final String memberId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;

  CheckIn({
    required this.id,
    required this.memberId,
    required this.checkInTime,
    this.checkOutTime,
  });

  bool get isCheckedIn => checkOutTime == null;

  Duration? get duration {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  CheckIn copyWith({
    String? id,
    String? memberId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
  }) {
    return CheckIn(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
    };
  }

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'],
      memberId: json['memberId'],
      checkInTime: DateTime.parse(json['checkInTime']),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
    );
  }

  // SQLite mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'checkInTime': checkInTime.millisecondsSinceEpoch,
      'checkOutTime': checkOutTime?.millisecondsSinceEpoch,
    };
  }

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      id: map['id'],
      memberId: map['memberId'],
      checkInTime: DateTime.fromMillisecondsSinceEpoch(
        map['checkInTime'] as int,
      ),
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['checkOutTime'] as int)
          : null,
    );
  }
}
