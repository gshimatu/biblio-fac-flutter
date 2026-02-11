import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String description;
  final String? coverUrl;
  final String category;
  final int totalCopies;
  final int availableCopies;
  final String publishedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.description,
    this.coverUrl,
    required this.category,
    required this.totalCopies,
    required this.availableCopies,
    required this.publishedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BookModel(
      id: documentId,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      isbn: map['isbn'] ?? '',
      description: map['description'] ?? '',
      coverUrl: map['coverUrl'],
      category: map['category'] ?? '',
      totalCopies: map['totalCopies'] ?? 0,
      availableCopies: map['availableCopies'] ?? 0,
      publishedDate: map['publishedDate'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'isbn': isbn,
      'description': description,
      'coverUrl': coverUrl,
      'category': category,
      'totalCopies': totalCopies,
      'availableCopies': availableCopies,
      'publishedDate': publishedDate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BookModel copyWith({
    String? title,
    String? author,
    String? isbn,
    String? description,
    String? coverUrl,
    String? category,
    int? totalCopies,
    int? availableCopies,
    DateTime? updatedAt,
  }) {
    return BookModel(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      category: category ?? this.category,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      publishedDate: publishedDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
