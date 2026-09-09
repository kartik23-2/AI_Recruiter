/// Complete interview session result and report models.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'answer_evaluation.dart';
import 'interview_config.dart';
import 'interview_question.dart';

/// A single Q&A entry within an interview.
class InterviewQA {
  final InterviewQuestion question;
  final String answer;
  final String transcript;
  final AnswerEvaluation? evaluation;

  const InterviewQA({
    required this.question,
    required this.answer,
    this.transcript = '',
    this.evaluation,
  });

  Map<String, dynamic> toFirestoreMap() => {
    'question': question.toFirestoreMap(),
    'answer': answer,
    'transcript': transcript,
    'evaluation': evaluation?.toFirestoreMap(),
  };

  factory InterviewQA.fromFirestore(Map<String, dynamic> data) {
    return InterviewQA(
      question: InterviewQuestion.fromFirestore(
        Map<String, dynamic>.from(data['question'] ?? {}),
      ),
      answer: data['answer']?.toString() ?? '',
      transcript: data['transcript']?.toString() ?? '',
      evaluation: data['evaluation'] != null
          ? AnswerEvaluation.fromFirestore(
              Map<String, dynamic>.from(data['evaluation']),
            )
          : null,
    );
  }
}

/// The generated interview report.
class InterviewReport {
  final int overallScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final String communicationAnalysis;
  final String technicalAnalysis;
  final List<String> areasToImprove;
  final List<String> recommendedTopics;
  final List<String> recommendedQuestions;

  const InterviewReport({
    required this.overallScore,
    required this.strengths,
    required this.weaknesses,
    required this.communicationAnalysis,
    required this.technicalAnalysis,
    required this.areasToImprove,
    required this.recommendedTopics,
    required this.recommendedQuestions,
  });

  factory InterviewReport.fromJson(Map<String, dynamic> json) {
    return InterviewReport(
      overallScore: _parseInt(json['overall_score']),
      strengths: _parseList(json['strengths']),
      weaknesses: _parseList(json['weaknesses']),
      communicationAnalysis: json['communication_analysis']?.toString() ?? '',
      technicalAnalysis: json['technical_analysis']?.toString() ?? '',
      areasToImprove: _parseList(json['areas_to_improve']),
      recommendedTopics: _parseList(json['recommended_topics']),
      recommendedQuestions: _parseList(json['recommended_questions']),
    );
  }

  Map<String, dynamic> toFirestoreMap() => {
    'overallScore': overallScore,
    'strengths': strengths,
    'weaknesses': weaknesses,
    'communicationAnalysis': communicationAnalysis,
    'technicalAnalysis': technicalAnalysis,
    'areasToImprove': areasToImprove,
    'recommendedTopics': recommendedTopics,
    'recommendedQuestions': recommendedQuestions,
  };

  factory InterviewReport.fromFirestore(Map<String, dynamic> data) {
    return InterviewReport(
      overallScore: _parseInt(data['overallScore'] ?? data['overall_score']),
      strengths: _parseList(data['strengths']),
      weaknesses: _parseList(data['weaknesses']),
      communicationAnalysis:
          (data['communicationAnalysis'] ?? data['communication_analysis'] ?? '')
              .toString(),
      technicalAnalysis:
          (data['technicalAnalysis'] ?? data['technical_analysis'] ?? '')
              .toString(),
      areasToImprove: _parseList(data['areasToImprove'] ?? data['areas_to_improve']),
      recommendedTopics:
          _parseList(data['recommendedTopics'] ?? data['recommended_topics']),
      recommendedQuestions:
          _parseList(data['recommendedQuestions'] ?? data['recommended_questions']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value.clamp(0, 100);
    if (value is double) return value.round().clamp(0, 100);
    if (value is String) return (int.tryParse(value) ?? 0).clamp(0, 100);
    return 0;
  }

  static List<String> _parseList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
}

/// Full interview session result stored in Firestore.
class InterviewResult {
  final String? id;
  final InterviewConfig config;
  final List<InterviewQA> qaEntries;
  final InterviewReport? report;
  final DateTime createdAt;

  const InterviewResult({
    this.id,
    required this.config,
    required this.qaEntries,
    this.report,
    required this.createdAt,
  });

  /// Average overall score across all evaluated answers.
  int get averageScore {
    final evaluated = qaEntries
        .where((e) => e.evaluation != null)
        .toList();
    if (evaluated.isEmpty) return 0;
    final sum = evaluated.fold<int>(
      0,
      (acc, e) => acc + e.evaluation!.overall,
    );
    return (sum / evaluated.length).round();
  }

  Map<String, dynamic> toFirestoreMap() => {
    'config': config.toFirestoreMap(),
    'qaEntries': qaEntries.map((e) => e.toFirestoreMap()).toList(),
    'report': report?.toFirestoreMap(),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory InterviewResult.fromFirestore(String docId, Map<String, dynamic> data) {
    final qaRaw = data['qaEntries'];
    final qaList = <InterviewQA>[];
    if (qaRaw is List) {
      for (final item in qaRaw) {
        if (item is Map) {
          qaList.add(InterviewQA.fromFirestore(Map<String, dynamic>.from(item)));
        }
      }
    }

    final reportRaw = data['report'];
    InterviewReport? report;
    if (reportRaw is Map) {
      report = InterviewReport.fromFirestore(Map<String, dynamic>.from(reportRaw));
    }

    DateTime createdAt = DateTime.now();
    final createdAtRaw = data['createdAt'];
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    }

    return InterviewResult(
      id: docId,
      config: InterviewConfig.fromFirestore(
        Map<String, dynamic>.from(data['config'] ?? {}),
      ),
      qaEntries: qaList,
      report: report,
      createdAt: createdAt,
    );
  }
}
