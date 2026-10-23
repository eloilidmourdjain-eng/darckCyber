import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  static final FirebaseAuthService instance = FirebaseAuthService._init();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuthService._init();

  // --- AUTHENTIFICATION ---
  Future<Map<String, dynamic>?> authenticateUser(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          data['id'] = credential.user!.uid;
          return data;
        }
      }
    } catch (e) {
      print("Erreur de connexion Firebase: $e");
    }
    return null;
  }

  // --- PROVISIONNEMENT D'UN ADMIN ---
  Future<void> provisionAdmin(String id, String name, String email, String tempPassword) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'simpleAdmin',
        'is_first_login': 1,
        'is_active': 1,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // --- MISE À JOUR DU PROFIL ---
  Future<void> completeUserProfile(String email, String newPassword) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.updatePassword(newPassword);
        await _firestore.collection('users').doc(currentUser.uid).update({
          'is_first_login': 0,
        });
      }
    } catch (e) {
      rethrow;
    }
  }
}