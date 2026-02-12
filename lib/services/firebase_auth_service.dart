import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Inscription avec email et mot de passe
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Connexion avec email et mot de passe
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  /// Stream d'écoute de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
