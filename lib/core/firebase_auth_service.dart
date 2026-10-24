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
      print("DEBUG - Tentative de connexion Auth pour : $email");
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        print("DEBUG - Connexion Auth réussie. UID Firebase Auth : ${credential.user!.uid}");

        print("📡 [Firestore] Tentative de lecture du document pour l'UID : ${credential.user!.uid}");
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          print("✅ [Firestore] Communication réussie ! Données reçues : ${userDoc.data()}");
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          data['id'] = credential.user!.uid;
          return data;
        } else {
          print("❌ [Firestore] La base de données a répondu, mais aucun document ne correspond à cet UID.");
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