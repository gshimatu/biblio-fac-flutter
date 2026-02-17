import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';

class BookProvider extends ChangeNotifier {
  final BookService _bookService = BookService();

  List<BookModel> _books = [];
  bool _isLoading = false;
  String? _error;

  List<BookModel> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _books = await _bookService.getAllBooks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBook(BookModel book) async {
    await _bookService.addBook(book);
    await loadBooks();
  }

  Future<void> updateBook(BookModel book) async {
    await _bookService.updateBook(book);
    await loadBooks();
  }

  Future<void> deleteBook(String id) async {
    await _bookService.deleteBook(id);
    await loadBooks();
  }
}
