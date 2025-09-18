class Labour {
  final String id;
  final String name;
  final String details;
  final List<DateTime> attendance;
  final int perLiftPrice;
  final Map<String, int> dailyEarnings; // key: 'yyyy-MM-dd', value: total for that day

  Labour({
    required this.id,
    required this.name,
    required this.details,
    this.attendance = const [],
    required this.perLiftPrice,
    this.dailyEarnings = const {},
  });

  int get totalEarnings => dailyEarnings.values.fold(0, (a, b) => a + b);

  int monthlyEarnings(DateTime month) {
    final monthStr = "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}";
    return dailyEarnings.entries
      .where((e) => e.key.startsWith(monthStr))
      .fold(0, (a, b) => a + b.value);
  }

  Labour copyWith({
    String? id,
    String? name,
    String? details,
    List<DateTime>? attendance,
    int? perLiftPrice,
    Map<String, int>? dailyEarnings,
  }) {
    return Labour(
      id: id ?? this.id,
      name: name ?? this.name,
      details: details ?? this.details,
      attendance: attendance ?? this.attendance,
      perLiftPrice: perLiftPrice ?? this.perLiftPrice,
      dailyEarnings: dailyEarnings ?? this.dailyEarnings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'details': details,
      'attendance': attendance.map((d) => d.toIso8601String()).toList(),
      'perLiftPrice': perLiftPrice,
      'dailyEarnings': dailyEarnings,
    };
  }

  static Labour fromMap(Map<String, dynamic> map) {
    return Labour(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      details: map['details'] ?? '',
      attendance: (map['attendance'] as List<dynamic>? ?? []).map((d) => DateTime.parse(d as String)).toList(),
      perLiftPrice: map['perLiftPrice'] ?? 0,
      dailyEarnings: Map<String, int>.from(map['dailyEarnings'] ?? {}),
    );
  }
}