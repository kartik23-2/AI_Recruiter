// Firestore CRUD for interview results.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/interview_result.dart';

/// Persists interview sessions under users/{uid}/interviews/{interviewId}.
class InterviewRepository {
  InterviewRepository._();
  static final InterviewRepository instance = InterviewRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _interviewsRef(String uid) =>
      _db.collection('users').doc(uid).collection('interviews');

  /// Save a completed interview.
  Future<String> saveInterview({
    required String uid,
    required InterviewResult result,
  }) async {
    final doc = _interviewsRef(uid).doc();
    await doc.set(result.toFirestoreMap());
    return doc.id;
  }

  /// Read a single interview by ID.
  Future<InterviewResult?> readInterview({
    required String uid,
    required String interviewId,
  }) async {
    final doc = await _interviewsRef(uid).doc(interviewId).get();
    final data = doc.data();
    if (data == null) return null;
    return InterviewResult.fromFirestore(doc.id, data);
  }

  /// Delete an interview.
  Future<void> deleteInterview({
    required String uid,
    required String interviewId,
  }) async {
    await _interviewsRef(uid).doc(interviewId).delete();
  }

  /// Fetch all interviews for a user, most recent first.
  Future<List<InterviewResult>> fetchAllInterviews(String uid) async {
    final snapshot = await _interviewsRef(uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => InterviewResult.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Fetch the N most recent interviews.
  Future<List<InterviewResult>> fetchRecentInterviews(
    String uid, {
    int limit = 10,
  }) async {
    final snapshot = await _interviewsRef(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => InterviewResult.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Compute aggregate analytics.
  Future<Map<String, dynamic>> computeAnalytics(String uid) async {
    final interviews = await fetchAllInterviews(uid);
    if (interviews.isEmpty) {
      return {
        'totalInterviews': 0,
        'averageScore': 0,
        'bestScore': 0,
        'recentScores': <int>[],
      };
    }

    final scores = interviews
        .where((i) => i.report != null)
        .map((i) => i.report!.overallScore)
        .toList();

    final avgScore =
        scores.isEmpty ? 0 : (scores.reduce((a, b) => a + b) / scores.length).round();
    final bestScore = scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b);

    // Last 10 scores for the trend chart (oldest first)
    final recentScores = scores.take(10).toList().reversed.toList();

    return {
      'totalInterviews': interviews.length,
      'averageScore': avgScore,
      'bestScore': bestScore,
      'recentScores': recentScores,
    };
  }
}
