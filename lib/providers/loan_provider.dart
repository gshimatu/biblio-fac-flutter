import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/loan_model.dart';
import '../services/loan_service.dart';

class LoanProvider extends ChangeNotifier {
  final LoanService _loanService = LoanService();

  List<LoanModel> _loans = [];
  bool _isLoading = false;
  String? _error;

  List<LoanModel> get loans => _loans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserLoans() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _loans = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _loans = await _loanService.getLoansByUser(currentUser.uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllLoans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _loans = await _loanService.getAllLoans();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveLoan(String loanId) async {
    await _loanService.approveLoan(loanId);
    await loadAllLoans();
  }

  Future<void> rejectLoan(String loanId) async {
    await _loanService.rejectLoan(loanId);
    await loadAllLoans();
  }

  Future<void> markAsReturned(String loanId) async {
    await _loanService.markAsReturned(loanId);
    await loadAllLoans();
  }
}
