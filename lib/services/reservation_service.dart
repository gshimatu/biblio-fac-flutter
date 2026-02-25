import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reservations';

  /// Creer une reservation
  Future<void> createReservation(ReservationModel reservation) async {
    await _firestore.collection(_collection).add(reservation.toMap());
  }

  /// Recuperer toutes les reservations
  Future<List<ReservationModel>> getAllReservations() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Flux temps reel de toutes les reservations
  Stream<List<ReservationModel>> streamAllReservations() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Recuperer les reservations d'un utilisateur
  Future<List<ReservationModel>> getReservationsByUser(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Flux temps reel des reservations d'un utilisateur
  Stream<List<ReservationModel>> streamReservationsByUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Annuler une reservation
  Future<void> cancelReservation(String reservationId) async {
    await _firestore.collection(_collection).doc(reservationId).update({
      'status': ReservationStatus.cancelled.name,
    });
  }

  /// Marquer comme traitee
  Future<void> fulfillReservation(String reservationId) async {
    await _firestore.collection(_collection).doc(reservationId).update({
      'status': ReservationStatus.fulfilled.name,
    });
  }
}
