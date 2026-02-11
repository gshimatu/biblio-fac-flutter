import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_model.dart';

class LoanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'loans';

  /// Créer une demande d'emprunt
  Future<void> createLoan(LoanModel loan) async {
    await _firestore.collection(_collection).add(loan.toMap());
  }

  /// Récupérer tous les emprunts
  Future<List<LoanModel>> getAllLoans() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Récupérer les emprunts d’un utilisateur
  Future<List<LoanModel>> getLoansByUser(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Valider un emprunt (admin)
  Future<void> approveLoan(String loanId) async {
    await _firestore.collection(_collection).doc(loanId).update({
      'status': 'approved',
    });
  }

  /// Marquer comme retourné
  Future<void> markAsReturned(String loanId) async {
    await _firestore.collection(_collection).doc(loanId).update({
      'status': 'returned',
      'returnDate': Timestamp.now(),
    });
  }

  /// Refuser un emprunt
  Future<void> rejectLoan(String loanId) async {
    await _firestore.collection(_collection).doc(loanId).update({
      'status': 'rejected',
    });
  }
}
