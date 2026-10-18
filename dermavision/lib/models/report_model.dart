import 'dart:convert';

class ReportModel {
  final String id;
  final String userId;
  final String condition;
  final double confidence;
  final String severity;
  final DateTime date;
  final String imagePath;
  final String description;
  final String recommendation;
  final List<String> precautions;
  final String? skinStatus;
  final double? skinConfidence;

  const ReportModel({
    required this.id,
    required this.userId,
    required this.condition,
    required this.confidence,
    required this.severity,
    required this.date,
    required this.imagePath,
    this.description = '',
    this.recommendation = '',
    this.precautions = const [],
    this.skinStatus,
    this.skinConfidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'condition': condition,
      'confidence': confidence,
      'severity': severity,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
      'description': description,
      'recommendation': recommendation,
      'precautions': precautions,
      'skinStatus': skinStatus,
      'skinConfidence': skinConfidence,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      condition: map['condition'] ?? 'Unknown Condition',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.85,
      severity: map['severity'] ?? 'Low Risk',
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      imagePath: map['imagePath'] ?? '',
      description: map['description'] ?? '',
      recommendation: map['recommendation'] ?? '',
      precautions: List<String>.from(map['precautions'] ?? []),
      skinStatus: map['skinStatus'],
      skinConfidence: (map['skinConfidence'] as num?)?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReportModel.fromJson(String source) =>
      ReportModel.fromMap(json.decode(source));
}
