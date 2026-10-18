import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';

class ReportService {
  static const String _legacyReportsKey = 'dermavision_reports_storage';

  static String _userReportsKey(String userId) => 'dermavision_reports_v2_$userId';

  /// Fetch all reports for the specific [userId].
  /// User reports are strictly isolated by the Firebase user's unique UID.
  Future<List<ReportModel>> getReports(String userId) async {
    if (userId.trim().isEmpty) {
      return [];
    }

    final prefs = await SharedPreferences.getInstance();

    // Clean up old unscoped storage to prevent legacy data from leaking
    if (prefs.containsKey(_legacyReportsKey)) {
      await prefs.remove(_legacyReportsKey);
    }

    final key = _userReportsKey(userId);
    final reportsJson = prefs.getStringList(key);

    List<ReportModel> list = [];

    if (reportsJson != null && reportsJson.isNotEmpty) {
      try {
        list = reportsJson
            .map((e) => ReportModel.fromJson(e))
            .where((r) => r.userId == userId)
            .toList();
      } catch (e) {
        debugPrint('Error parsing local reports: $e');
        list = [];
      }
    }

    // Attempt to sync from Cloud Firestore if available and merge
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('reports')
          .orderBy('date', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.docs.isNotEmpty) {
        final remoteReports = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          data['userId'] = userId;
          return ReportModel.fromMap(data);
        }).toList();

        // Merge remote reports with local
        final existingIds = list.map((e) => e.id).toSet();
        for (final remote in remoteReports) {
          if (!existingIds.contains(remote.id)) {
            list.add(remote);
          }
        }
        // Save merged list back to per-user storage
        final jsonList = list.map((r) => r.toJson()).toList();
        await prefs.setStringList(key, jsonList);
      }
    } catch (e) {
      debugPrint('Firestore fetch note (using local cache): $e');
    }

    // Sort descending by date (latest first)
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Save a report strictly under the report's owner [report.userId].
  Future<void> saveReport(ReportModel report) async {
    if (report.userId.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _userReportsKey(report.userId);
    final reportsJson = prefs.getStringList(key) ?? [];

    List<ReportModel> list = [];
    try {
      list = reportsJson
          .map((e) => ReportModel.fromJson(e))
          .where((r) => r.userId == report.userId && r.id != report.id)
          .toList();
    } catch (_) {
      list = [];
    }

    list.insert(0, report);
    final jsonList = list.map((r) => r.toJson()).toList();
    await prefs.setStringList(key, jsonList);

    // Sync to Cloud Firestore asynchronously in background without blocking local return
    Future(() async {
      try {
        final firestore = FirebaseFirestore.instance;
        final mapData = report.toMap();
        // If imagePath is a large base64 string, omit it from remote Firestore document to stay well within 1MB limit
        if (report.imagePath.startsWith('data:image') && report.imagePath.length > 500000) {
          mapData['imagePath'] = '';
        }
        await firestore
            .collection('users')
            .doc(report.userId)
            .collection('reports')
            .doc(report.id)
            .set(mapData, SetOptions(merge: true))
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Firestore save sync note: $e');
      }
    });
  }

  /// Delete a report for a specific user.
  Future<void> deleteReport(String userId, String reportId) async {
    if (userId.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _userReportsKey(userId);
    final reportsJson = prefs.getStringList(key) ?? [];

    List<ReportModel> list = [];
    try {
      list = reportsJson
          .map((e) => ReportModel.fromJson(e))
          .where((r) => r.id != reportId && r.userId == userId)
          .toList();
    } catch (_) {
      list = [];
    }

    final jsonList = list.map((r) => r.toJson()).toList();
    await prefs.setStringList(key, jsonList);

    // Remove from Cloud Firestore in background
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('users')
          .doc(userId)
          .collection('reports')
          .doc(reportId)
          .delete();
    } catch (e) {
      debugPrint('Firestore delete sync note: $e');
    }
  }

  /// Get the latest report for [userId].
  Future<ReportModel?> getLatestReport(String userId) async {
    final list = await getReports(userId);
    if (list.isEmpty) return null;
    return list.first;
  }
}
