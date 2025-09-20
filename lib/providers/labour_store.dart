import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapabricks/models/labour.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MarkAttendanceResult { success, alreadyMarked, notFound }

class LabourStore extends ChangeNotifier {
  final Map<String, Labour> _labours = {}; // id -> Labour
  bool _loaded = false;
  bool get loaded => _loaded;

  // This persists scan cooldowns
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
    required int perLiftPrice,
  }) {
    final docRef = FirebaseFirestore.instance.collection('labours').doc();
    final labour = Labour(
      id: docRef.id,
      name: name,
      details: details,
      perLiftPrice: perLiftPrice,
      attendance: [],
      dailyRecords: {},
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
    required int perLiftPrice,
  }) {
    final labour = _labours[id];
    if (labour != null) {
      final updatedLabour = labour.copyWith(
        name: name,
        details: details,
        perLiftPrice: perLiftPrice,
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
    final today = DateTime(now.year, now.month, now.day);

    final already = labour.attendance.any(
      (d) => d.year == today.year && d.month == today.month && d.day == today.day,
    );

    if (already) {
      return MarkAttendanceResult.alreadyMarked;
    }

    final updatedAttendance = [...labour.attendance, today];
    final updatedLabour = labour.copyWith(attendance: updatedAttendance);
    FirebaseFirestore.instance.collection('labours').doc(id).update({
      'attendance': updatedAttendance.map((d) => d.toIso8601String()).toList(),
    });
    _labours[id] = updatedLabour;
    notifyListeners();
    return MarkAttendanceResult.success;
  }

  void addLift(String id) {
    final labour = _labours[id];
    if (labour != null) {
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
    }
  }

  // ========== PERSISTENT COOLDOWN LOGIC ==========

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
    // Store as "id,iso;id,iso;..." string
    final entries = scanCooldowns.entries
        .map((e) => '${e.key},${e.value.toIso8601String()}')
        .join(';');
    await prefs.setString('scanCooldowns', entries);
  }

  // Call this when scan occurs
  Future<void> updateScanCooldown(String id, DateTime time) async {
    scanCooldowns[id] = time;
    await _saveScanCooldowns();
  }
}