import 'dart:async';

import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/google_book_model.dart';
import '../controllers/book_controller.dart';
import '../services/book_service.dart';
import '../services/google_books_service.dart';

class BookProvider extends ChangeNotifier {
  final BookController _bookController = BookController();
  final BookService _bookService = BookService();
  StreamSubscription<List<BookModel>>? _booksSubscription;

  List<BookModel> _books = [];
  List<GoogleBookModel> _externalBooks = [];
  bool _isLoading = false;
  bool _isExternalLoading = false;
  String? _error;
  String? _externalError;

  List<BookModel> get books => _books;
  List<GoogleBookModel> get externalBooks => _externalBooks;
  bool get isLoading => _isLoading;
  bool get isExternalLoading => _isExternalLoading;
  String? get error => _error;
  String? get externalError => _externalError;

  Future<void> loadBooks() async {
    await _booksSubscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _books = await _bookController.getAllBooks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBook(BookModel book) async {
    await _bookController.addBook(book);
    await loadBooks();
  }

  Future<void> updateBook(BookModel book) async {
    await _bookController.updateBook(book);
    await loadBooks();
  }

  Future<void> deleteBook(String id) async {
    await _bookController.deleteBook(id);
    await loadBooks();
  }

  Future<void> startBooksRealtime() async {
    await _booksSubscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _booksSubscription = _bookService.streamAllBooks().listen(
      (books) {
        _books = books;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> stopBooksRealtime() async {
    await _booksSubscription?.cancel();
    _booksSubscription = null;
  }

  Future<void> searchExternalBooks({
    required String query,
    required GoogleBookSearchType type,
  }) async {
    _isExternalLoading = true;
    _externalError = null;
    notifyListeners();

    try {
      _externalBooks = await _bookController.searchExternalBooks(
        query: query,
        type: type,
      );
    } catch (e) {
      _externalError = e.toString();
      _externalBooks = [];
    } finally {
      _isExternalLoading = false;
      notifyListeners();
    }
  }

  void clearExternalResults() {
    _externalBooks = [];
    _externalError = null;
    _isExternalLoading = false;
    notifyListeners();
  }

  Future<void> importExternalBook(BookModel book) async {
    await _bookController.importGoogleBookToCatalog(book);
    await loadBooks();
  }

  @override
  void dispose() {
    _booksSubscription?.cancel();
    super.dispose();
  }
}
