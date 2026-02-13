import 'package:flutter/material.dart';
import '../models/loan_model.dart';

class LoanProvider extends ChangeNotifier {
  List<LoanModel> _loans = [];
  bool _isLoading = false;

  List<LoanModel> get loans => _loans;
  bool get isLoading => _isLoading;

  Future<void> loadUserLoans() async {
    // Simuler un chargement
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _loans = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllLoans() async {
    // Simuler un chargement
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _loans = [];
    _isLoading = false;
    notifyListeners();
  }
}