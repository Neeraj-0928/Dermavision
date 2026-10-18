import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  List<ReportModel> _reports = [];
  bool _isLoading = false;
  String? _activeUserId;

  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  int get totalCount => _reports.length;
  String? get activeUserId => _activeUserId;

  ReportModel? get latestReport => _reports.isNotEmpty ? _reports.first : null;

  Future<void> loadReports(String userId) async {
    if (userId.trim().isEmpty) {
      _reports = [];
      _activeUserId = null;
      notifyListeners();
      return;
    }

    _activeUserId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      _reports = await _reportService.getReports(userId);
    } catch (_) {
      _reports = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReport(ReportModel report) async {
    await _reportService.saveReport(report);
    if (_activeUserId == null || _activeUserId == report.userId) {
      _reports.removeWhere((r) => r.id == report.id);
      _reports.insert(0, report);
      _reports.sort((a, b) => b.date.compareTo(a.date));
    }
    notifyListeners();
  }

  Future<void> deleteReport(String userId, String reportId) async {
    await _reportService.deleteReport(userId, reportId);
    _reports.removeWhere((r) => r.id == reportId);
    notifyListeners();
  }

  void clearReports() {
    _reports = [];
    _activeUserId = null;
    notifyListeners();
  }
}
