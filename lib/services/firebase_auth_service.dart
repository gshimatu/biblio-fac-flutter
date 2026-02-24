import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _isGoogleInitialized = false;
  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '424910647692-0qaffqk2k8naa8hp70r2hko9jb38uncj.apps.googleusercontent.com',
  );

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

  /// Connexion avec Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      }

      if (!_isGoogleInitialized) {
        await _googleSignIn.initialize(clientId: _googleWebClientId);
        _isGoogleInitialized = true;
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final String? idToken = googleUser.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Token Google invalide. Verifiez la configuration Firebase.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Connexion Google annulee.');
      }
      throw Exception(e.description);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Deconnexion
  Future<void> logout() async {
    await _auth.signOut();
    if (_isGoogleInitialized) {
      await _googleSignIn.signOut();
    }
  }

  /// Utilisateur actuellement connecte
  User? get currentUser => _auth.currentUser;

  /// Stream d'ecoute de l'etat d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
