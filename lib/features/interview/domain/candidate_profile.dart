import 'package:cloud_firestore/cloud_firestore.dart';

/// Structured profile extracted from a resume PDF.
class CandidateProfile {
  final String name;
  final List<String> skills;
  final List<String> projects;
  final List<String> education;
  final List<String> experience;
  final List<String> strengths;
  final List<String> weakAreas;
  final DateTime? analyzedAt;

  const CandidateProfile({
    required this.name,
    required this.skills,
    required this.projects,
    required this.education,
    required this.experience,
    required this.strengths,
    required this.weakAreas,
    required this.analyzedAt,
  });

  factory CandidateProfile.fromJson(Map<String, dynamic> json) {
    return CandidateProfile(
      name: _parseString(json['name']),
      skills: _parseStringList(json['skills']),
      projects: _parseStringList(json['projects']),
      education: _parseStringList(json['education']),
      experience: _parseStringList(json['experience']),
      strengths: _parseStringList(json['strengths']),
      weakAreas: _parseStringList(json['weakAreas']),
      analyzedAt: _parseDateTime(json['analyzedAt']),
    );
  }

  factory CandidateProfile.fromFirestore(Map<String, dynamic> data) {
    return CandidateProfile(
      name: _parseString(data['name']),
      skills: _parseStringList(data['skills']),
      projects: _parseStringList(data['projects']),
      education: _parseStringList(data['education']),
      experience: _parseStringList(data['experience']),
      strengths: _parseStringList(data['strengths']),
      weakAreas: _parseStringList(data['weakAreas']),
      analyzedAt: _parseDateTime(data['analyzedAt']),
    );
  }

  CandidateProfile copyWith({
    String? name,
    List<String>? skills,
    List<String>? projects,
    List<String>? education,
    List<String>? experience,
    List<String>? strengths,
    List<String>? weakAreas,
    DateTime? analyzedAt,
    bool clearAnalyzedAt = false,
  }) {
    return CandidateProfile(
      name: name ?? this.name,
      skills: skills ?? this.skills,
      projects: projects ?? this.projects,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      strengths: strengths ?? this.strengths,
      weakAreas: weakAreas ?? this.weakAreas,
      analyzedAt: clearAnalyzedAt ? null : analyzedAt ?? this.analyzedAt,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .where((e) => e != null)
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty && s != 'null')
          .toList();
    }
    return [];
  }

  static String _parseString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'skills': skills,
    'projects': projects,
    'education': education,
    'experience': experience,
    'strengths': strengths,
    'weakAreas': weakAreas,
    'analyzedAt': analyzedAt?.toIso8601String(),
  };

  Map<String, dynamic> toFirestoreMap() => {
    'name': name,
    'skills': skills,
    'projects': projects,
    'education': education,
    'experience': experience,
    'strengths': strengths,
    'weakAreas': weakAreas,
    'analyzedAt': analyzedAt != null ? Timestamp.fromDate(analyzedAt!) : null,
  };
}
