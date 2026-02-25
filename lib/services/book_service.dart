import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'books';

  /// Ajouter un livre
  Future<void> addBook(BookModel book) async {
    await _firestore.collection(_collection).add(book.toMap());
  }

  /// Recuperer tous les livres
  Future<List<BookModel>> getAllBooks() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => BookModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Flux temps reel du catalogue de livres
  Stream<List<BookModel>> streamAllBooks() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BookModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Recuperer un livre par ID
  Future<BookModel?> getBookById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return BookModel.fromMap(doc.data()!, doc.id);
  }

  /// Mettre a jour un livre
  Future<void> updateBook(BookModel book) async {
    await _firestore.collection(_collection).doc(book.id).update(book.toMap());
  }

  /// Supprimer un livre
  Future<void> deleteBook(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Recherche par titre
  Future<List<BookModel>> searchByTitle(String title) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('title', isGreaterThanOrEqualTo: title)
        .where('title', isLessThanOrEqualTo: '$title\uf8ff')
        .get();

    return snapshot.docs
        .map((doc) => BookModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Recherche exacte par ISBN
  Future<BookModel?> getBookByIsbn(String isbn) async {
    final normalized = isbn.trim();
    if (normalized.isEmpty) return null;

    final snapshot = await _firestore
        .collection(_collection)
        .where('isbn', isEqualTo: normalized)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return BookModel.fromMap(doc.data(), doc.id);
  }
}
