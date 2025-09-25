class Labour {
  final String id;
  final String name;
  final String details;
  final String occupation; // "Labour", "Driver", "Staff"
  final List<DateTime> attendance;
  final int perLiftPrice;
  final int? dailyIncome; // Only for staff
  final String? brickType; // <-- ADD THIS LINE
  // key: 'yyyy-MM-dd', value: { 'earnings': X, 'lifts': Y }
  final Map<String, Map<String, int>> dailyRecords;
  // key: 'yyyy-MM-dd', value: { 'arrival': DateTime, 'departure': DateTime }
  final Map<String, Map<String, DateTime>> attendanceTimes;

  Labour({
    required this.id,
    required this.name,
    required this.details,
    required this.occupation,
    this.attendance = const [],
    required this.perLiftPrice,
    this.dailyIncome,
    this.brickType, // <-- ADD THIS LINE
    this.dailyRecords = const {},
    this.attendanceTimes = const {},
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
    String? occupation,
    List<DateTime>? attendance,
    int? perLiftPrice,
    int? dailyIncome,
    String? brickType, // <-- ADD THIS LINE
    Map<String, Map<String, int>>? dailyRecords,
    Map<String, Map<String, DateTime>>? attendanceTimes,
  }) {
    return Labour(
      id: id ?? this.id,
      name: name ?? this.name,
      details: details ?? this.details,
      occupation: occupation ?? this.occupation,
      attendance: attendance ?? this.attendance,
      perLiftPrice: perLiftPrice ?? this.perLiftPrice,
      dailyIncome: dailyIncome ?? this.dailyIncome,
      brickType: brickType ?? this.brickType, // <-- ADD THIS LINE
      dailyRecords: dailyRecords ?? this.dailyRecords,
      attendanceTimes: attendanceTimes ?? this.attendanceTimes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'details': details,
      'occupation': occupation,
      'attendance': attendance.map((d) => d.toIso8601String()).toList(),
      'perLiftPrice': perLiftPrice,
      'dailyIncome': dailyIncome,
      'brickType': brickType, // <-- ADD THIS LINE
      'dailyRecords': dailyRecords,
      'attendanceTimes': attendanceTimes.map((date, times) => MapEntry(
        date,
        {
          if (times['arrival'] != null) 'arrival': times['arrival']!.toIso8601String(),
          if (times['departure'] != null) 'departure': times['departure']!.toIso8601String(),
        }
      )),
    };
  }

  static Labour fromMap(Map<String, dynamic> map) {
    final attendanceTimesRaw = map['attendanceTimes'] as Map<String, dynamic>? ?? {};
    final attendanceTimes = <String, Map<String, DateTime>>{};
    attendanceTimesRaw.forEach((date, timesRaw) {
      final timesMap = <String, DateTime>{};
      if (timesRaw is Map) {
        if (timesRaw['arrival'] != null) {
          timesMap['arrival'] = DateTime.parse(timesRaw['arrival']);
        }
        if (timesRaw['departure'] != null) {
          timesMap['departure'] = DateTime.parse(timesRaw['departure']);
        }
      }
      attendanceTimes[date] = timesMap;
    });

    return Labour(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      details: map['details'] ?? '',
      occupation: map['occupation'] ?? 'Labour',
      attendance: (map['attendance'] as List<dynamic>? ?? []).map((d) => DateTime.parse(d as String)).toList(),
      perLiftPrice: map['perLiftPrice'] ?? 0,
      dailyIncome: map['dailyIncome'],
      brickType: map['brickType'], // <-- ADD THIS LINE
      dailyRecords: Map<String, Map<String, int>>.from(
        (map['dailyRecords'] ?? {}).map((k, v) => MapEntry(k, Map<String, int>.from(v)))
      ),
      attendanceTimes: attendanceTimes,
    );
  }
}