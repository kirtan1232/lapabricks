import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapabricks/models/labour.dart';
import 'package:lapabricks/models/daily_total.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MarkAttendanceResult { success, alreadyMarked, notFound, departureMarked }

class LabourStore extends ChangeNotifier {
  final Map<String, Labour> _labours = {};
  bool _loaded = false;
  bool get loaded => _loaded;

  final Map<String, DateTime> scanCooldowns = {};

  LabourStore() {
    loadLaboursAsync();
    _loadScanCooldowns();
  }

  List<Labour> get labours {
    final sorted = _labours.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  Future<void> loadLaboursAsync() async {
    await _loadLabours();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _loadLabours() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('labours').get();
    _labours.clear();
    for (var doc in querySnapshot.docs) {
      final labour = Labour.fromMap({...doc.data(), 'id': doc.id});
      _labours[labour.id] = labour;
    }
  }

  Labour? byId(String id) => _labours[id];

  Labour addLabour({
    required String name,
    required String details,
    required String occupation,
    required int perLiftPrice,
    int? dailyIncome,
  }) {
    final docRef = FirebaseFirestore.instance.collection('labours').doc();
    final labour = Labour(
      id: docRef.id,
      name: name,
      details: details,
      occupation: occupation,
      perLiftPrice: perLiftPrice,
      dailyIncome: dailyIncome,
      attendance: [],
      dailyRecords: {},
      attendanceTimes: {},
    );
    docRef.set(labour.toMap());
    _labours[labour.id] = labour;
    notifyListeners();
    return labour;
  }

  void editLabour({
    required String id,
    required String name,
    required String details,
    required String occupation,
    required int perLiftPrice,
    int? dailyIncome,
  }) {
    final labour = _labours[id];
    if (labour != null) {
      final updatedLabour = labour.copyWith(
        name: name,
        details: details,
        occupation: occupation,
        perLiftPrice: perLiftPrice,
        dailyIncome: dailyIncome,
      );
      FirebaseFirestore.instance.collection('labours').doc(id).set(updatedLabour.toMap());
      _labours[id] = updatedLabour;
      notifyListeners();
    }
  }

  void deleteLabour(String id) {
    FirebaseFirestore.instance.collection('labours').doc(id).delete();
    _labours.remove(id);
    scanCooldowns.remove(id);
    _saveScanCooldowns();
    notifyListeners();
  }

  MarkAttendanceResult markAttendanceById(String id) {
    final labour = _labours[id];
    if (labour == null) return MarkAttendanceResult.notFound;

    final now = DateTime.now();
    final todayStr = "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
    final attendanceTimes = Map<String, Map<String, DateTime>>.from(labour.attendanceTimes);

    if (labour.occupation == 'Staff') {
      if (!attendanceTimes.containsKey(todayStr) || attendanceTimes[todayStr]!['arrival'] == null) {
        attendanceTimes[todayStr] = {
          'arrival': now,
        };
        final updatedAttendance = [...labour.attendance, DateTime(now.year, now.month, now.day)];
        final newDailyRecords = Map<String, Map<String, int>>.from(labour.dailyRecords);
        newDailyRecords[todayStr] = {
          'earnings': labour.dailyIncome ?? 0,
          'lifts': 0,
        };
        final updatedLabour = labour.copyWith(
          attendance: updatedAttendance,
          attendanceTimes: attendanceTimes,
          dailyRecords: newDailyRecords,
        );
        FirebaseFirestore.instance.collection('labours').doc(id).update(updatedLabour.toMap());
        _labours[id] = updatedLabour;
        notifyListeners();
        updateDailyTotals(now);
        return MarkAttendanceResult.success;
      } else {
        attendanceTimes[todayStr]!['departure'] = now;
        final updatedLabour = labour.copyWith(
          attendanceTimes: attendanceTimes,
        );
        FirebaseFirestore.instance.collection('labours').doc(id).update({
          'attendanceTimes': updatedLabour.attendanceTimes.map((date, times) => MapEntry(
            date,
            {
              if (times['arrival'] != null) 'arrival': times['arrival']!.toIso8601String(),
              if (times['departure'] != null) 'departure': times['departure']!.toIso8601String(),
            }
          )),
        });
        _labours[id] = updatedLabour;
        notifyListeners();
        updateDailyTotals(now);
        return MarkAttendanceResult.departureMarked;
      }
    }

    if (!attendanceTimes.containsKey(todayStr) || attendanceTimes[todayStr]!['arrival'] == null) {
      attendanceTimes[todayStr] = {
        'arrival': now,
      };
      final updatedAttendance = [...labour.attendance, DateTime(now.year, now.month, now.day)];
      final updatedLabour = labour.copyWith(
        attendance: updatedAttendance,
        attendanceTimes: attendanceTimes,
      );
      FirebaseFirestore.instance.collection('labours').doc(id).update({
        'attendance': updatedAttendance.map((d) => d.toIso8601String()).toList(),
        'attendanceTimes': updatedLabour.attendanceTimes.map((date, times) => MapEntry(
          date,
          {
            if (times['arrival'] != null) 'arrival': times['arrival']!.toIso8601String(),
            if (times['departure'] != null) 'departure': times['departure']!.toIso8601String(),
          }
        )),
      });
      _labours[id] = updatedLabour;
      notifyListeners();
      updateDailyTotals(now);
      return MarkAttendanceResult.success;
    } else {
      attendanceTimes[todayStr]!['departure'] = now;
      final updatedLabour = labour.copyWith(
        attendanceTimes: attendanceTimes,
      );
      FirebaseFirestore.instance.collection('labours').doc(id).update({
        'attendanceTimes': updatedLabour.attendanceTimes.map((date, times) => MapEntry(
          date,
          {
            if (times['arrival'] != null) 'arrival': times['arrival']!.toIso8601String(),
            if (times['departure'] != null) 'departure': times['departure']!.toIso8601String(),
          }
        )),
      });
      _labours[id] = updatedLabour;
      notifyListeners();
      return MarkAttendanceResult.departureMarked;
    }
  }

  void addLift(String id) {
    final labour = _labours[id];
    if (labour != null) {
      if (labour.occupation == 'Staff') return;
      final now = DateTime.now();
      final todayStr = "${now.year.toString().padLeft(4, '0')}-"
          "${now.month.toString().padLeft(2, '0')}-"
          "${now.day.toString().padLeft(2, '0')}";
      final prev = labour.dailyRecords[todayStr] ?? {'earnings': 0, 'lifts': 0};
      final newRecord = {
        'earnings': (prev['earnings'] ?? 0) + labour.perLiftPrice,
        'lifts': (prev['lifts'] ?? 0) + 1,
      };
      final newDailyRecords = Map<String, Map<String, int>>.from(labour.dailyRecords);
      newDailyRecords[todayStr] = newRecord;
      final updatedLabour = labour.copyWith(dailyRecords: newDailyRecords);
      FirebaseFirestore.instance.collection('labours').doc(id).update({
        'dailyRecords': newDailyRecords,
      });
      _labours[id] = updatedLabour;
      notifyListeners();
      updateDailyTotals(now);
    }
  }

  int todayBricks(String id) {
    final labour = byId(id);
    if (labour == null) return 0;
    final liftDetail = _parseLiftDetail(labour.details);
    final todayStr = "${DateTime.now().year.toString().padLeft(4, '0')}-"
        "${DateTime.now().month.toString().padLeft(2, '0')}-"
        "${DateTime.now().day.toString().padLeft(2, '0')}";
    final todayRecord = labour.dailyRecords[todayStr];
    return (todayRecord?['lifts'] ?? 0) * liftDetail;
  }

  int totalBricks(String id) {
    final labour = byId(id);
    if (labour == null) return 0;
    final liftDetail = _parseLiftDetail(labour.details);
    int total = 0;
    labour.dailyRecords.forEach((date, record) {
      total += (record['lifts'] ?? 0) * liftDetail;
    });
    return total;
  }

  int _parseLiftDetail(String details) {
    final regex = RegExp(r'Lift:\s*(\d+)');
    final match = regex.firstMatch(details);
    if (match != null) return int.tryParse(match.group(1) ?? '1') ?? 1;
    return 1;
  }

  Future<void> updateDailyTotals(DateTime date) async {
    final todayStr = "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    int labour_lifts = 0, labour_earnings = 0;
    int driver_lifts = 0, driver_earnings = 0;
    int staff_earnings = 0;

    for (final l in labours) {
      final record = l.dailyRecords[todayStr];
      if (record != null) {
        if (l.occupation == 'Labour') {
          labour_lifts += record['lifts'] ?? 0;
          labour_earnings += record['earnings'] ?? 0;
        } else if (l.occupation == 'Driver') {
          driver_lifts += record['lifts'] ?? 0;
          driver_earnings += record['earnings'] ?? 0;
        } else if (l.occupation == 'Staff') {
          staff_earnings += record['earnings'] ?? 0;
        }
      }
    }

    final overall_lifts = labour_lifts + driver_lifts;
    final overall_earnings = labour_earnings + driver_earnings + staff_earnings;

    final dailyTotal = DailyTotal(
      date: todayStr,
      labourTotalLifts: labour_lifts,
      labourTotalEarnings: labour_earnings,
      driverTotalLifts: driver_lifts,
      driverTotalEarnings: driver_earnings,
      staffTotalEarnings: staff_earnings,
      overallTotalLifts: overall_lifts,
      overallTotalEarnings: overall_earnings,
    );

    final docRef = FirebaseFirestore.instance.collection('daily_total').doc(todayStr);
    await docRef.set(dailyTotal.toMap(), SetOptions(merge: true));
  }

  Future<void> _loadScanCooldowns() async {
    final prefs = await SharedPreferences.getInstance();
    final mapString = prefs.getString('scanCooldowns');
    if (mapString != null && mapString.isNotEmpty) {
      final entries = mapString.split(';');
      for (final entry in entries) {
        final parts = entry.split(',');
        if (parts.length == 2) {
          final id = parts[0];
          final time = DateTime.tryParse(parts[1]);
          if (time != null) {
            scanCooldowns[id] = time;
          }
        }
      }
    }
  }

  Future<void> _saveScanCooldowns() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = scanCooldowns.entries
        .map((e) => '${e.key},${e.value.toIso8601String()}')
        .join(';');
    await prefs.setString('scanCooldowns', entries);
  }

  Future<void> updateScanCooldown(String id, DateTime time) async {
    scanCooldowns[id] = time;
    await _saveScanCooldowns();
  }
}