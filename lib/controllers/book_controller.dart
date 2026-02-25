import '../models/book_model.dart';
import '../models/google_book_model.dart';
import '../services/book_service.dart';
import '../services/google_books_service.dart';

class BookController {
  final BookService _bookService = BookService();
  final GoogleBooksService _googleBooksService = GoogleBooksService();

  Future<List<BookModel>> getAllBooks() {
    return _bookService.getAllBooks();
  }

  Future<void> addBook(BookModel book) {
    return _bookService.addBook(book);
  }

  Future<void> updateBook(BookModel book) {
    return _bookService.updateBook(book);
  }

  Future<void> deleteBook(String id) {
    return _bookService.deleteBook(id);
  }

  Future<List<GoogleBookModel>> searchExternalBooks({
    required String query,
    required GoogleBookSearchType type,
    int maxResults = 20,
  }) {
    return _googleBooksService.searchBooks(
      query: query,
      type: type,
      maxResults: maxResults,
    );
  }

  Future<void> importGoogleBookToCatalog(BookModel book) async {
    final isbn = book.isbn.trim();
    if (isbn.isNotEmpty) {
      final existing = await _bookService.getBookByIsbn(isbn);
      if (existing != null) {
        throw Exception('Un livre avec cet ISBN existe deja dans le catalogue.');
      }
    }
    await _bookService.addBook(book);
  }
}
