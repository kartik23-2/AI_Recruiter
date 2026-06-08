import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/user_model.dart';

/// Singleton wrapper around Cloud Firestore for user records.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Create a new user document in the "users" collection.
  Future<void> createUserRecord({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _users.doc(uid).set({
      'uid': uid,
      'name': name.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch an existing user document by uid.
  Future<UserModel?> getUserRecord(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc);
  }
}
