class Labour {
  final String id;
  final String name;
  final String details;
  final List<DateTime> attendance;
  final int perLiftPrice;
  // key: 'yyyy-MM-dd', value: { 'earnings': X, 'lifts': Y }
  final Map<String, Map<String, int>> dailyRecords;

  Labour({
    required this.id,
    required this.name,
    required this.details,
    this.attendance = const [],
    required this.perLiftPrice,
    this.dailyRecords = const {},
  });

  int get totalEarnings => dailyRecords.values.fold(0, (a, b) => a + (b['earnings'] ?? 0));

  int monthlyEarnings(DateTime month) {
    final monthStr = "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}";
    return dailyRecords.entries
      .where((e) => e.key.startsWith(monthStr))
      .fold(0, (a, b) => a + (b.value['earnings'] ?? 0));
  }

  Labour copyWith({
    String? id,
    String? name,
    String? details,
    List<DateTime>? attendance,
    int? perLiftPrice,
    Map<String, Map<String, int>>? dailyRecords,
  }) {
    return Labour(
      id: id ?? this.id,
      name: name ?? this.name,
      details: details ?? this.details,
      attendance: attendance ?? this.attendance,
      perLiftPrice: perLiftPrice ?? this.perLiftPrice,
      dailyRecords: dailyRecords ?? this.dailyRecords,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'details': details,
      'attendance': attendance.map((d) => d.toIso8601String()).toList(),
      'perLiftPrice': perLiftPrice,
      'dailyRecords': dailyRecords,
    };
  }

  static Labour fromMap(Map<String, dynamic> map) {
    return Labour(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      details: map['details'] ?? '',
      attendance: (map['attendance'] as List<dynamic>? ?? []).map((d) => DateTime.parse(d as String)).toList(),
      perLiftPrice: map['perLiftPrice'] ?? 0,
      dailyRecords: Map<String, Map<String, int>>.from(
        (map['dailyRecords'] ?? {}).map((k, v) => MapEntry(k, Map<String, int>.from(v)))
      ),
    );
  }
}