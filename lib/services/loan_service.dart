import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_model.dart';

class LoanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'loans';
  final String _booksCollection = 'books';
  static const int _loanDurationDays = 14;

  /// Creer une demande d'emprunt
  Future<void> createLoan(LoanModel loan) async {
    await _firestore.collection(_collection).add(loan.toMap());
  }

  /// Recuperer tous les emprunts
  Future<List<LoanModel>> getAllLoans() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Recuperer les emprunts d'un utilisateur
  Future<List<LoanModel>> getLoansByUser(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Valider un emprunt (admin):
  /// - decremente le stock disponible
  /// - fixe la date de debut a "maintenant"
  /// - fixe l'echeance a 14 jours
  Future<void> approveLoan(String loanId) async {
    final loanRef = _firestore.collection(_collection).doc(loanId);
    await _firestore.runTransaction((tx) async {
      final loanSnap = await tx.get(loanRef);
      if (!loanSnap.exists) {
        throw Exception('Emprunt introuvable.');
      }

      final loanData = loanSnap.data()!;
      final currentStatus = (loanData['status'] ?? '').toString();
      if (currentStatus != LoanStatus.pending.name) {
        throw Exception('Seul un emprunt en attente peut etre approuve.');
      }

      final bookId = (loanData['bookId'] ?? '').toString();
      if (bookId.isEmpty) {
        throw Exception('Livre de l\'emprunt introuvable.');
      }

      final bookRef = _firestore.collection(_booksCollection).doc(bookId);
      final bookSnap = await tx.get(bookRef);
      if (!bookSnap.exists) {
        throw Exception('Livre introuvable.');
      }

      final bookData = bookSnap.data()!;
      final availableCopies = (bookData['availableCopies'] as num?)?.toInt() ?? 0;
      if (availableCopies <= 0) {
        throw Exception('Aucun exemplaire disponible pour ce livre.');
      }

      final now = DateTime.now();
      final dueDate = now.add(const Duration(days: _loanDurationDays));

      tx.update(bookRef, {
        'availableCopies': availableCopies - 1,
        'updatedAt': Timestamp.now(),
      });
      tx.update(loanRef, {
        'status': LoanStatus.approved.name,
        'loanDate': Timestamp.fromDate(now),
        'dueDate': Timestamp.fromDate(dueDate),
        'returnDate': null,
      });
    });
  }

  /// Marquer comme retourne (admin):
  /// - met le pret en "returned"
  /// - renseigne la date de retour
  /// - re-incremente le stock disponible
  Future<void> markAsReturned(String loanId) async {
    final loanRef = _firestore.collection(_collection).doc(loanId);
    await _firestore.runTransaction((tx) async {
      final loanSnap = await tx.get(loanRef);
      if (!loanSnap.exists) {
        throw Exception('Emprunt introuvable.');
      }

      final loanData = loanSnap.data()!;
      final currentStatus = (loanData['status'] ?? '').toString();
      if (currentStatus != LoanStatus.approved.name) {
        throw Exception('Seul un emprunt approuve peut etre retourne.');
      }

      final bookId = (loanData['bookId'] ?? '').toString();
      if (bookId.isEmpty) {
        throw Exception('Livre de l\'emprunt introuvable.');
      }

      final bookRef = _firestore.collection(_booksCollection).doc(bookId);
      final bookSnap = await tx.get(bookRef);
      if (!bookSnap.exists) {
        throw Exception('Livre introuvable.');
      }

      final bookData = bookSnap.data()!;
      final totalCopies = (bookData['totalCopies'] as num?)?.toInt() ?? 0;
      final availableCopies = (bookData['availableCopies'] as num?)?.toInt() ?? 0;
      final nextAvailable =
          totalCopies > 0 ? (availableCopies + 1).clamp(0, totalCopies) : availableCopies + 1;

      tx.update(bookRef, {
        'availableCopies': nextAvailable,
        'updatedAt': Timestamp.now(),
      });
      tx.update(loanRef, {
        'status': LoanStatus.returned.name,
        'returnDate': Timestamp.now(),
      });
    });
  }

  /// Refuser un emprunt
  Future<void> rejectLoan(String loanId) async {
    await _firestore.collection(_collection).doc(loanId).update({
      'status': LoanStatus.rejected.name,
    });
  }
}
