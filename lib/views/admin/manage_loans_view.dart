import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/book_model.dart';
import '../../models/loan_model.dart';
import '../../models/user_model.dart';
import '../../services/book_service.dart';
import '../../services/loan_service.dart';
import '../../services/user_service.dart';

enum _LoanSortOption { recent, dueSoon, dueLate }

class ManageLoansView extends StatefulWidget {
  const ManageLoansView({super.key});

  @override
  State<ManageLoansView> createState() => _ManageLoansViewState();
}

class _ManageLoansViewState extends State<ManageLoansView> {
  final LoanService _loanService = LoanService();
  final BookService _bookService = BookService();
  final UserService _userService = UserService();

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<LoanModel>>? _loansSubscription;

  List<LoanModel> _loans = [];
  Map<String, BookModel> _booksById = {};
  Map<String, UserModel> _usersById = {};

  String _search = '';
  String _statusFilter = 'Tous';
  _LoanSortOption _sortOption = _LoanSortOption.recent;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
    _initializeRealtime();
  }

  @override
  void dispose() {
    _loansSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeRealtime() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([_bookService.getAllBooks(), _userService.getAllUsers()]);
      final books = results[0] as List<BookModel>;
      final users = results[1] as List<UserModel>;

      if (!mounted) return;
      setState(() {
        _booksById = {for (final b in books) b.id: b};
        _usersById = {for (final u in users) u.uid: u};
      });

      await _loansSubscription?.cancel();
      _loansSubscription = _loanService.streamAllLoans().listen(
        (loans) {
          if (!mounted) return;
          setState(() {
            _loans = loans;
            _isLoading = false;
            _error = null;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _error = _friendlyError(error);
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<LoanModel> _filteredLoans() {
    var loans = _loans.where((loan) {
      if (_statusFilter != 'Tous' && loan.status.name != _statusFilter) {
        return false;
      }
      if (_search.isEmpty) return true;
      final book = _booksById[loan.bookId];
      final user = _usersById[loan.userId];
      return (book?.title.toLowerCase().contains(_search) ?? false) ||
          (book?.author.toLowerCase().contains(_search) ?? false) ||
          (user?.fullName.toLowerCase().contains(_search) ?? false) ||
          (user?.email.toLowerCase().contains(_search) ?? false);
    }).toList();

    switch (_sortOption) {
      case _LoanSortOption.recent:
        loans.sort((a, b) => b.loanDate.compareTo(a.loanDate));
        break;
      case _LoanSortOption.dueSoon:
        loans.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case _LoanSortOption.dueLate:
        loans.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        break;
    }
    return loans;
  }

  Future<void> _approve(LoanModel loan) async {
    await _executeAction(
      action: () => _loanService.approveLoan(loan.id),
      successMessage: 'Emprunt approuve.',
    );
  }

  Future<void> _reject(LoanModel loan) async {
    await _executeAction(
      action: () => _loanService.rejectLoan(loan.id),
      successMessage: 'Emprunt refuse.',
    );
  }

  Future<void> _markReturned(LoanModel loan) async {
    await _executeAction(
      action: () => _loanService.markAsReturned(loan.id),
      successMessage: 'Emprunt marque retourne.',
    );
  }

  Future<void> _executeAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action impossible: ${_friendlyError(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('permission-denied') || message.contains('PERMISSION_DENIED')) {
      return 'Acces Firestore refuse. Autorisez les droits admin dans les regles.';
    }
    return message;
  }

  String _statusLabel(LoanStatus status) {
    switch (status) {
      case LoanStatus.pending:
        return 'En attente';
      case LoanStatus.approved:
        return 'Approuve';
      case LoanStatus.returned:
        return 'Retourne';
      case LoanStatus.rejected:
        return 'Refuse';
    }
  }

  Color _statusColor(LoanStatus status) {
    switch (status) {
      case LoanStatus.pending:
        return const Color(0xFFFF9800);
      case LoanStatus.approved:
        return const Color(0xFF1D9E6C);
      case LoanStatus.returned:
        return const Color(0xFF5A5F7A);
      case LoanStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final loans = _filteredLoans();

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par livre ou utilisateur...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E6)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                          DropdownMenuItem(value: 'pending', child: Text('En attente')),
                          DropdownMenuItem(value: 'approved', child: Text('Approuves')),
                          DropdownMenuItem(value: 'returned', child: Text('Retournes')),
                          DropdownMenuItem(value: 'rejected', child: Text('Refuses')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _statusFilter = value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<_LoanSortOption>(
                        isExpanded: true,
                        initialValue: _sortOption,
                        decoration: const InputDecoration(
                          labelText: 'Trier',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: _LoanSortOption.recent,
                            child: Text('Plus recents'),
                          ),
                          DropdownMenuItem(
                            value: _LoanSortOption.dueSoon,
                            child: Text('Echeance proche'),
                          ),
                          DropdownMenuItem(
                            value: _LoanSortOption.dueLate,
                            child: Text('Echeance lointaine'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _sortOption = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _initializeRealtime,
                        child: loans.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 120),
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 64,
                                    color: const Color(0xFF272662).withValues(alpha: 0.35),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'Aucun emprunt trouve',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF5A5F7A),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                itemCount: loans.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final loan = loans[index];
                                  final book = _booksById[loan.bookId];
                                  final user = _usersById[loan.userId];
                                  final statusColor = _statusColor(loan.status);

                                  return Card(
                                    elevation: 0.7,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  book?.title ?? 'Livre introuvable',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.sora(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF272662),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(18),
                                                ),
                                                child: Text(
                                                  _statusLabel(loan.status),
                                                  style: GoogleFonts.poppins(
                                                    color: statusColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${user?.fullName ?? 'Utilisateur inconnu'} • '
                                            '${book?.author ?? '-'}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFF5A5F7A),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _chip('Debut ${_formatDate(loan.loanDate)}'),
                                              _chip('Echeance ${_formatDate(loan.dueDate)}'),
                                              if (loan.returnDate != null)
                                                _chip('Retour ${_formatDate(loan.returnDate!)}'),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              if (loan.status == LoanStatus.pending) ...[
                                                OutlinedButton(
                                                  onPressed: () => _reject(loan),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  child: const Text('Refuser'),
                                                ),
                                                FilledButton(
                                                  onPressed: () => _approve(loan),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: const Color(0xFF1D9E6C),
                                                  ),
                                                  child: const Text('Approuver'),
                                                ),
                                              ],
                                              if (loan.status == LoanStatus.approved)
                                                FilledButton(
                                                  onPressed: () => _markReturned(loan),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: const Color(0xFF272662),
                                                  ),
                                                  child: const Text('Marquer retourne'),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: const Color(0xFF272662),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
