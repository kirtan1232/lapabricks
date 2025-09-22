class DailyTotal {
  final String date; // yyyy-MM-dd
  final int labourTotalLifts;
  final int labourTotalEarnings;
  final int driverTotalLifts;
  final int driverTotalEarnings;
  final int staffTotalEarnings;
  final int overallTotalLifts;
  final int overallTotalEarnings;

  DailyTotal({
    required this.date,
    required this.labourTotalLifts,
    required this.labourTotalEarnings,
    required this.driverTotalLifts,
    required this.driverTotalEarnings,
    required this.staffTotalEarnings,
    required this.overallTotalLifts,
    required this.overallTotalEarnings,
  });

  factory DailyTotal.fromMap(String id, Map<String, dynamic> map) {
    return DailyTotal(
      date: id,
      labourTotalLifts: map['labour_total_lifts'] ?? 0,
      labourTotalEarnings: map['labour_total_earnings'] ?? 0,
      driverTotalLifts: map['driver_total_lifts'] ?? 0,
      driverTotalEarnings: map['driver_total_earnings'] ?? 0,
      staffTotalEarnings: map['staff_total_earnings'] ?? 0,
      overallTotalLifts: map['overall_total_lifts'] ?? 0,
      overallTotalEarnings: map['overall_total_earnings'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'labour_total_lifts': labourTotalLifts,
      'labour_total_earnings': labourTotalEarnings,
      'driver_total_lifts': driverTotalLifts,
      'driver_total_earnings': driverTotalEarnings,
      'staff_total_earnings': staffTotalEarnings,
      'overall_total_lifts': overallTotalLifts,
      'overall_total_earnings': overallTotalEarnings,
    };
  }
}