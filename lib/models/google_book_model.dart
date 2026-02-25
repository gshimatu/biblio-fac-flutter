class GoogleBookModel {
  final String title;
  final String author;
  final String isbn;
  final String description;
  final String? coverUrl;
  final String publishedDate;

  GoogleBookModel({
    required this.title,
    required this.author,
    required this.isbn,
    required this.description,
    required this.coverUrl,
    required this.publishedDate,
  });

  factory GoogleBookModel.fromApiMap(Map<String, dynamic> map) {
    final volumeInfo = (map['volumeInfo'] as Map<String, dynamic>?) ?? const {};
    final imageLinks =
        (volumeInfo['imageLinks'] as Map<String, dynamic>?) ?? const {};
    final identifiers =
        (volumeInfo['industryIdentifiers'] as List<dynamic>?) ?? const [];

    String isbn = '';
    for (final item in identifiers) {
      if (item is! Map<String, dynamic>) continue;
      final type = (item['type'] ?? '').toString();
      final value = (item['identifier'] ?? '').toString().trim();
      if (value.isEmpty) continue;
      if (type == 'ISBN_13') {
        isbn = value;
        break;
      }
      if (isbn.isEmpty && type == 'ISBN_10') {
        isbn = value;
      }
    }

    final authors = (volumeInfo['authors'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final title = (volumeInfo['title'] ?? '').toString().trim();
    final author =
        authors.isEmpty ? 'Auteur inconnu' : authors.join(', ');
    final description = (volumeInfo['description'] ?? '')
        .toString()
        .trim();
    final coverUrl = (imageLinks['thumbnail'] ?? imageLinks['smallThumbnail'])
        ?.toString()
        .replaceFirst('http://', 'https://');
    final publishedDate = (volumeInfo['publishedDate'] ?? '')
        .toString()
        .trim();

    return GoogleBookModel(
      title: title.isEmpty ? 'Titre inconnu' : title,
      author: author,
      isbn: isbn,
      description: description,
      coverUrl: (coverUrl == null || coverUrl.isEmpty) ? null : coverUrl,
      publishedDate: publishedDate,
    );
  }
}
