import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/labour.dart';

enum MarkAttendanceResult { success, alreadyMarked, notFound }

class LabourStore extends ChangeNotifier {
  final Map<String, Labour> _labours = {}; // id -> Labour
  bool _loaded = false;
  bool get loaded => _loaded;

  List<Labour> get labours {
    final sorted = _labours.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  LabourStore() {
    loadLaboursAsync();
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
      dailyEarnings: {},
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
    final previousTodayEarnings = labour.dailyEarnings[todayStr] ?? 0;
    final previousTodayLifts = labour.dailyLifts[todayStr] ?? 0;
    final dailyTotalEarnings = previousTodayEarnings + labour.perLiftPrice;
    final dailyTotalLifts = previousTodayLifts + 1;
    final newDailyEarnings = Map<String, int>.from(labour.dailyEarnings);
    final newDailyLifts = Map<String, int>.from(labour.dailyLifts);
    newDailyEarnings[todayStr] = dailyTotalEarnings;
    newDailyLifts[todayStr] = dailyTotalLifts;
    final updatedLabour = labour.copyWith(dailyEarnings: newDailyEarnings, dailyLifts: newDailyLifts);
    FirebaseFirestore.instance.collection('labours').doc(id).update({
      'dailyEarnings': newDailyEarnings,
      'dailyLifts': newDailyLifts,
    });
    _labours[id] = updatedLabour;
    notifyListeners();
  }
}
}