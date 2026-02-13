import 'package:flutter/material.dart';
import '../models/book_model.dart';

class BookProvider extends ChangeNotifier {
  List<BookModel> _books = [];
  bool _isLoading = false;

  List<BookModel> get books => _books;
  bool get isLoading => _isLoading;

  Future<void> loadBooks() async {
    // Simuler un chargement
    _isLoading = true;
    notifyListeners();

    // Données factices
    await Future.delayed(const Duration(milliseconds: 500));
    _books = [
      BookModel(
        id: '1',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        isbn: '9780132350884',
        description: 'Un guide pour écrire du code propre et maintenable.',
        category: 'Informatique',
        totalCopies: 5,
        availableCopies: 3,
        publishedDate: '2008',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // ... autres livres factices
    ];

    _isLoading = false;
    notifyListeners();
  }
}