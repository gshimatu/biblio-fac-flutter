import 'package:cloud_firestore/cloud_firestore.dart';

enum LoanStatus { pending, approved, returned, rejected }

class LoanModel {
  final String id;
  final String userId;
  final String bookId;
  final DateTime loanDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final LoanStatus status;

  LoanModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.loanDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
  });

  factory LoanModel.fromMap(Map<String, dynamic> map, String documentId) {
    return LoanModel(
      id: documentId,
      userId: map['userId'],
      bookId: map['bookId'],
      loanDate: (map['loanDate'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      returnDate: map['returnDate'] != null
          ? (map['returnDate'] as Timestamp).toDate()
          : null,
      status: LoanStatus.values
          .firstWhere((e) => e.name == map['status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'loanDate': Timestamp.fromDate(loanDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'returnDate':
          returnDate != null ? Timestamp.fromDate(returnDate!) : null,
      'status': status.name,
    };
  }
}
