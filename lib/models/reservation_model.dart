import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'une réservation.
enum ReservationStatus { active, cancelled, fulfilled }

/// Modèle décrivant une réservation d'un livre par un utilisateur.
class ReservationModel {
  final String id;
  final String userId;
  final String bookId;
  final DateTime reservationDate;
  final ReservationStatus status;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.reservationDate,
    required this.status,
  });

  factory ReservationModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return ReservationModel(
      id: documentId,
      userId: map['userId'],
      bookId: map['bookId'],
      reservationDate: (map['reservationDate'] as Timestamp).toDate(),
      // status stocké sous forme textuelle ('active', 'cancelled', ...)
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'reservationDate': Timestamp.fromDate(reservationDate),
      'status': status.name,
    };
  }
}
