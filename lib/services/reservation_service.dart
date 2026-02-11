import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reservations';

  /// Créer une réservation
  Future<void> createReservation(ReservationModel reservation) async {
    await _firestore.collection(_collection).add(reservation.toMap());
  }

  /// Récupérer toutes les réservations
  Future<List<ReservationModel>> getAllReservations() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Réservations d’un utilisateur
  Future<List<ReservationModel>> getReservationsByUser(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Annuler une réservation
  Future<void> cancelReservation(String reservationId) async {
    await _firestore.collection(_collection).doc(reservationId).update({
      'status': 'cancelled',
    });
  }

  /// Marquer comme traitée
  Future<void> fulfillReservation(String reservationId) async {
    await _firestore.collection(_collection).doc(reservationId).update({
      'status': 'fulfilled',
    });
  }
}
