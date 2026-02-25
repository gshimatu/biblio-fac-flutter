import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../models/google_book_model.dart';

enum GoogleBookSearchType { title, author, isbn }

class GoogleBooksService {
  static const String _baseUrl =
      'https://www.googleapis.com/books/v1/volumes';
  static const String _apiKey =
      String.fromEnvironment('GOOGLE_BOOKS_API_KEY', defaultValue: '');

  Future<List<GoogleBookModel>> searchBooks({
    required String query,
    GoogleBookSearchType type = GoogleBookSearchType.title,
    int maxResults = 20,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    final prefix = switch (type) {
      GoogleBookSearchType.title => 'intitle:',
      GoogleBookSearchType.author => 'inauthor:',
      GoogleBookSearchType.isbn => 'isbn:',
    };

    final params = <String, String>{
      'q': '$prefix$trimmedQuery',
      'maxResults': maxResults.clamp(1, 40).toString(),
      'printType': 'books',
      'langRestrict': 'fr',
    };
    if (_apiKey.isNotEmpty) {
      params['key'] = _apiKey;
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception(
          'Google Books a retourne ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) return [];

      final items = payload['items'];
      if (items is! List) return [];

      return items
          .whereType<Map<String, dynamic>>()
          .map(GoogleBookModel.fromApiMap)
          .toList();
    } on SocketException {
      throw Exception('Aucune connexion internet.');
    } on http.ClientException {
      throw Exception('Erreur reseau lors de l\'appel a Google Books.');
    } on FormatException {
      throw Exception('Reponse Google Books invalide.');
    } on TimeoutException {
      throw Exception('Google Books ne repond pas (timeout).');
    }
  }
}
