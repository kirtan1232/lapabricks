class Labour {
  final String id;
  final String name;
  final String details;
  final List<DateTime> attendance;
  final int heavyPayments;
  final int lowPayments;

  Labour({
    required this.id,
    required this.name,
    required this.details,
    this.attendance = const [],
    this.heavyPayments = 0,
    this.lowPayments = 0,
  });

  Labour copyWith({
    String? id,
    String? name,
    String? details,
    List<DateTime>? attendance,
    int? heavyPayments,
    int? lowPayments,
  }) {
    return Labour(
      id: id ?? this.id,
      name: name ?? this.name,
      details: details ?? this.details,
      attendance: attendance ?? this.attendance,
      heavyPayments: heavyPayments ?? this.heavyPayments,
      lowPayments: lowPayments ?? this.lowPayments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'details': details,
      'attendance': attendance.map((d) => d.toIso8601String()).toList(),
      'heavyPayments': heavyPayments,
      'lowPayments': lowPayments,
    };
  }

  static Labour fromMap(Map<String, dynamic> map) {
    return Labour(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      details: map['details'] ?? '',
      attendance: (map['attendance'] as List<dynamic>? ?? []).map((d) => DateTime.parse(d as String)).toList(),
      heavyPayments: map['heavyPayments'] ?? 0,
      lowPayments: map['lowPayments'] ?? 0,
    );
  }
}