import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  /// Créer un nouvel utilisateur
  Future<void> createUser(UserModel user) async {
    await _firestore.collection(_collection).doc(user.uid).set(user.toMap());
  }

  /// Récupérer un utilisateur par UID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Mettre à jour les informations utilisateur
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection(_collection).doc(user.uid).update(user.toMap());
  }

  /// Mettre à jour uniquement le lastLogin
  Future<void> updateLastLogin(String uid) async {
    await _firestore.collection(_collection).doc(uid).update({
      'lastLogin': Timestamp.now(),
    });
  }

  /// Désactiver un compte
  Future<void> deactivateUser(String uid) async {
    await _firestore.collection(_collection).doc(uid).update({
      'isActive': false,
    });
  }

  /// Activer un compte
  Future<void> activateUser(String uid) async {
    await _firestore.collection(_collection).doc(uid).update({
      'isActive': true,
    });
  }

  /// Mettre à jour le rôle
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _firestore.collection(_collection).doc(uid).update({
      'role': role.name,
    });
  }

  /// Supprimer un utilisateur
  Future<void> deleteUser(String uid) async {
    await _firestore.collection(_collection).doc(uid).delete();
  }

  /// Récupérer tous les utilisateurs (admin)
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
