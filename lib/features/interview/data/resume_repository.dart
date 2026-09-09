import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/candidate_profile.dart';

/// Persists the analyzed resume profile under the authenticated user record.
class ResumeRepository {
  ResumeRepository._();
  static final ResumeRepository instance = ResumeRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<CandidateProfile?> readProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (data == null) return null;

    final rawProfile = data['resumeProfile'];
    if (rawProfile is Map<String, dynamic>) {
      return CandidateProfile.fromFirestore(rawProfile);
    }
    if (rawProfile is Map) {
      return CandidateProfile.fromFirestore(
        Map<String, dynamic>.from(rawProfile),
      );
    }
    return null;
  }

  Future<void> saveProfile({
    required String uid,
    required CandidateProfile profile,
  }) async {
    await _users.doc(uid).set({
      'resumeProfile': profile.toFirestoreMap(),
    }, SetOptions(merge: true));
  }

  Future<void> updateProfile({
    required String uid,
    required CandidateProfile profile,
  }) async {
    await saveProfile(uid: uid, profile: profile);
  }
}
