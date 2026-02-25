import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/loan_model.dart';
import '../services/loan_service.dart';

class LoanProvider extends ChangeNotifier {
  final LoanService _loanService = LoanService();
  StreamSubscription<List<LoanModel>>? _subscription;

  List<LoanModel> _loans = [];
  bool _isLoading = false;
  String? _error;

  List<LoanModel> get loans => _loans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserLoans() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      await _subscription?.cancel();
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

  Future<void> startUserLoansRealtime({String? userId}) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      await _subscription?.cancel();
      _loans = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    await _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _loanService.streamLoansByUser(uid).listen(
      (loans) {
        _loans = loans;
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

  Future<void> startAllLoansRealtime() async {
    await _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _loanService.streamAllLoans().listen(
      (loans) {
        _loans = loans;
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

  Future<void> stopRealtime() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> approveLoan(String loanId) async {
    await _loanService.approveLoan(loanId);
  }

  Future<void> rejectLoan(String loanId) async {
    await _loanService.rejectLoan(loanId);
  }

  Future<void> markAsReturned(String loanId) async {
    await _loanService.markAsReturned(loanId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
