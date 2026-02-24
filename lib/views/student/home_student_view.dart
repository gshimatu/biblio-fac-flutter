import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../models/loan_model.dart';
import '../../models/reservation_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/loan_provider.dart';
import '../../services/loan_service.dart';
import '../../services/reservation_service.dart';
import 'book_details_view.dart';

class HomeStudentView extends StatefulWidget {
  const HomeStudentView({super.key});

  @override
  State<HomeStudentView> createState() => _HomeStudentViewState();
}

class _HomeStudentViewState extends State<HomeStudentView> {
  final LoanService _loanService = LoanService();
  final ReservationService _reservationService = ReservationService();

  int _tab = 0;
  bool _loaded = false;
  bool _loadingReservations = false;
  List<ReservationModel> _reservations = [];

  String _searchDashboard = '';
  String _searchCategories = '';
  String _searchLoans = '';
  String _searchReservations = '';

  String _selectedCategory = 'Toutes';
  String _loanStatus = 'Tous';
  String _reservationStatus = 'Tous';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_loaded) return;
      await _reload();
      _loaded = true;
    });
  }

  Future<void> _reload() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;
    final books = Provider.of<BookProvider>(context, listen: false);
    final loans = Provider.of<LoanProvider>(context, listen: false);
    setState(() => _loadingReservations = true);
    await Future.wait([books.loadBooks(), loans.loadUserLoans()]);
    try {
      final reservations = await _reservationService.getReservationsByUser(user.uid);
      if (mounted) setState(() => _reservations = reservations);
    } finally {
      if (mounted) setState(() => _loadingReservations = false);
    }
  }

  Future<void> _reserve(BookModel book) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;
    if (!_canUseLibraryFeatures(user)) return;
    final exists = _reservations.any(
      (r) => r.bookId == book.id && r.status == ReservationStatus.active,
    );
    if (exists) {
      _snack('Reservation deja active.');
      return;
    }
    await _reservationService.createReservation(
      ReservationModel(
        id: '',
        userId: user.uid,
        bookId: book.id,
        reservationDate: DateTime.now(),
        status: ReservationStatus.active,
      ),
    );
    await _reload();
    _snack('Reservation creee.');
  }

  Future<void> _borrow(BookModel book) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    if (user == null) return;
    if (!_canUseLibraryFeatures(user)) return;
    final exists = loanProvider.loans.any(
      (l) =>
          l.bookId == book.id &&
          (l.status == LoanStatus.pending || l.status == LoanStatus.approved),
    );
    if (exists) {
      _snack('Demande deja existante pour ce livre.');
      return;
    }
    await _loanService.createLoan(
      LoanModel(
        id: '',
        userId: user.uid,
        bookId: book.id,
        loanDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 14)),
        returnDate: null,
        status: LoanStatus.pending,
      ),
    );
    await loanProvider.loadUserLoans();
    _snack('Demande d\'emprunt envoyee.');
  }

  Future<void> _cancelReservation(ReservationModel reservation) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;
    if (!_canUseLibraryFeatures(user)) return;

    await _reservationService.cancelReservation(reservation.id);
    await _reload();
    _snack('Reservation annulee.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _canUseLibraryFeatures(UserModel user) {
    if (user.isActive) return true;
    _snack(
      'Compte non active. Presentez votre preuve de paiement a la bibliotheque pour activation.',
    );
    return false;
  }

  Widget _buildInactiveAccountBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.warning_amber_rounded, color: Colors.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Votre compte n\'est pas encore active. Veuillez presenter une preuve '
              'de paiement des frais de bibliotheque a l\'administrateur pour activation.',
              style: GoogleFonts.poppins(
                color: const Color(0xFF8A4B00),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _missingRequiredProfileFields(UserModel user) {
    final missing = <String>[];
    if (user.fullName.trim().isEmpty) missing.add('Nom complet');
    if (user.email.trim().isEmpty) missing.add('Email');
    if ((user.phoneNumber ?? '').trim().isEmpty) missing.add('Telephone');
    if ((user.address ?? '').trim().isEmpty) missing.add('Adresse');
    if ((user.faculty ?? '').trim().isEmpty) missing.add('Faculte');
    if ((user.promotion ?? '').trim().isEmpty) missing.add('Promotion');
    if ((user.matricule ?? '').trim().isEmpty) missing.add('Matricule');
    return missing;
  }

  String _title() {
    const titles = [
      'Dashboard Etudiant',
      'Categories',
      'Mes Reservations',
      'Mes Emprunts',
      'Statistiques',
    ];
    return titles[_tab];
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final booksProvider = Provider.of<BookProvider>(context);
    final loanProvider = Provider.of<LoanProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final books = booksProvider.books;
    final loans = loanProvider.loans;
    final missingFields = _missingRequiredProfileFields(user);
    final categories = <String>{'Toutes', ...books.map((b) => b.category)}.toList()..sort();
    final isInactive = !user.isActive;
    if (!categories.contains(_selectedCategory)) _selectedCategory = 'Toutes';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _title(),
          style: GoogleFonts.sora(
            color: const Color(0xFF272662),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (missingFields.isNotEmpty)
            IconButton(
              tooltip: 'Profil incomplet: ${missingFields.length} champ(s) manquant(s)',
              onPressed: () {
                Navigator.of(context).pushNamed('/profile');
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${missingFields.length}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed('/profile');
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE9ECF8),
                  child: ClipOval(
                    child: Image.network(
                      user.profileImageUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, color: Color(0xFF272662));
                      },
                    ),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.person, color: Color(0xFF272662)),
              onPressed: () {
                Navigator.of(context).pushNamed('/profile');
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF272662)),
            onPressed: () async {
              await auth.logout();
              if (mounted) Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (isInactive) _buildInactiveAccountBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: _body(books, loans, categories),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedItemColor: const Color(0xFF272662),
        unselectedItemColor: const Color(0xFF5A5F7A),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Reservations'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Emprunts'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }

  Widget _body(List<BookModel> books, List<LoanModel> loans, List<String> categories) {
    switch (_tab) {
      case 1:
        return _categoriesTab(books, categories);
      case 2:
        return _reservationsTab(books);
      case 3:
        return _loansTab(books, loans);
      case 4:
        return _statsTab(books, loans);
      default:
        return _dashboardTab(books);
    }
  }

  Widget _searchField(String hint, ValueChanged<String> onChanged) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _dashboardTab(List<BookModel> books) {
    final filtered = books.where((b) {
      final q = _searchDashboard.toLowerCase();
      if (q.isEmpty) return true;
      return b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.isbn.toLowerCase().contains(q);
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _searchField('Rechercher un livre...', (v) => setState(() => _searchDashboard = v)),
        const SizedBox(height: 12),
        Text('Livres disponibles', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _booksGrid(filtered),
      ],
    );
  }

  Widget _categoriesTab(List<BookModel> books, List<String> categories) {
    final filtered = books.where((b) {
      final catOk = _selectedCategory == 'Toutes' || b.category == _selectedCategory;
      if (!catOk) return false;
      final q = _searchCategories.toLowerCase();
      if (q.isEmpty) return true;
      return b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q);
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _searchField('Rechercher dans les categories...', (v) => setState(() => _searchCategories = v)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories
              .map(
                (c) => ChoiceChip(
                  label: Text(c, maxLines: 1, overflow: TextOverflow.ellipsis),
                  selected: _selectedCategory == c,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _booksGrid(filtered),
      ],
    );
  }

  Widget _reservationsTab(List<BookModel> books) {
    final filtered = _reservations.where((r) {
      if (_reservationStatus != 'Tous' && r.status.name != _reservationStatus) return false;
      final q = _searchReservations.toLowerCase();
      if (q.isEmpty) return true;
      final book = books.where((b) => b.id == r.bookId).firstWhere(
            (_) => true,
            orElse: () => BookModel(
              id: '', title: '', author: '', isbn: '', description: '', category: '',
              totalCopies: 0, availableCopies: 0, publishedDate: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
            ),
          );
      return book.title.toLowerCase().contains(q) || book.author.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _searchField('Rechercher reservation...', (v) => setState(() => _searchReservations = v)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _reservationStatus,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Statut'),
          items: const [
            DropdownMenuItem(value: 'Tous', child: Text('Tous')),
            DropdownMenuItem(value: 'active', child: Text('Actives')),
            DropdownMenuItem(value: 'fulfilled', child: Text('Traitees')),
            DropdownMenuItem(value: 'cancelled', child: Text('Annulees')),
          ],
          onChanged: (v) => setState(() => _reservationStatus = v ?? 'Tous'),
        ),
        const SizedBox(height: 12),
        if (_loadingReservations) const Center(child: CircularProgressIndicator()) else ...filtered.map((r) {
          final book = books.where((b) => b.id == r.bookId).firstWhere(
                (_) => true,
                orElse: () => BookModel(
                  id: '', title: 'Livre introuvable', author: '-', isbn: '', description: '', category: '',
                  totalCopies: 0, availableCopies: 0, publishedDate: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
                ),
              );
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('Statut: ${r.status.name}'),
              trailing: r.status == ReservationStatus.active
                  ? TextButton(onPressed: () => _cancelReservation(r), child: const Text('Annuler'))
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _loansTab(List<BookModel> books, List<LoanModel> loans) {
    final filtered = loans.where((l) {
      if (_loanStatus != 'Tous' && l.status.name != _loanStatus) return false;
      final q = _searchLoans.toLowerCase();
      if (q.isEmpty) return true;
      final book = books.where((b) => b.id == l.bookId).firstWhere(
            (_) => true,
            orElse: () => BookModel(
              id: '', title: '', author: '', isbn: '', description: '', category: '',
              totalCopies: 0, availableCopies: 0, publishedDate: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
            ),
          );
      return book.title.toLowerCase().contains(q) || book.author.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _searchField('Rechercher emprunt...', (v) => setState(() => _searchLoans = v)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _loanStatus,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Statut'),
          items: const [
            DropdownMenuItem(value: 'Tous', child: Text('Tous')),
            DropdownMenuItem(value: 'pending', child: Text('En attente')),
            DropdownMenuItem(value: 'approved', child: Text('Approuves')),
            DropdownMenuItem(value: 'returned', child: Text('Retournes')),
            DropdownMenuItem(value: 'rejected', child: Text('Refuses')),
          ],
          onChanged: (v) => setState(() => _loanStatus = v ?? 'Tous'),
        ),
        const SizedBox(height: 12),
        ...filtered.map((l) {
          final book = books.where((b) => b.id == l.bookId).firstWhere(
                (_) => true,
                orElse: () => BookModel(
                  id: '', title: 'Livre introuvable', author: '-', isbn: '', description: '', category: '',
                  totalCopies: 0, availableCopies: 0, publishedDate: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
                ),
              );
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('Statut: ${l.status.name} • Echeance: ${l.dueDate.day}/${l.dueDate.month}/${l.dueDate.year}'),
            ),
          );
        }),
      ],
    );
  }

  Widget _statsTab(List<BookModel> books, List<LoanModel> loans) {
    final pending = loans.where((l) => l.status == LoanStatus.pending).length;
    final approved = loans.where((l) => l.status == LoanStatus.approved).length;
    final returned = loans.where((l) => l.status == LoanStatus.returned).length;
    final activeRes = _reservations.where((r) => r.status == ReservationStatus.active).length;
    final totalLoans = loans.length;
    final completionRate = totalLoans == 0 ? 0 : ((returned / totalLoans) * 100).round();
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 2;

    final stats = [
      ('Demandes', pending, const Color(0xFF4C52A3)),
      ('Approuves', approved, const Color(0xFF1D9E6C)),
      ('Retournes', returned, const Color(0xFF2E86DE)),
      ('Res. actives', activeRes, const Color(0xFF9B59B6)),
    ];
    final max = stats.fold<int>(1, (m, e) => e.$2 > m ? e.$2 : m).toDouble();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF272662), Color(0xFF4C52A3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.insights, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vue globale',
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Taux de retour: $completionRate%',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _smallMetric(
              title: 'Livres',
              value: '${books.length}',
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF272662),
              width: cardWidth,
            ),
            _smallMetric(
              title: 'Reservations',
              value: '${_reservations.length}',
              icon: Icons.bookmark_added_rounded,
              color: const Color(0xFF9B59B6),
              width: cardWidth,
            ),
            _smallMetric(
              title: 'Emprunts',
              value: '$totalLoans',
              icon: Icons.assignment_turned_in_rounded,
              color: const Color(0xFF1D9E6C),
              width: cardWidth,
            ),
            _smallMetric(
              title: 'En cours',
              value: '$approved',
              icon: Icons.schedule_rounded,
              color: const Color(0xFFFFA726),
              width: cardWidth,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Repartition',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF272662),
                ),
              ),
              const SizedBox(height: 12),
              ...stats.map((s) {
                final ratio = s.$2 == 0 ? 0.0 : s.$2 / max;
                final percent = max == 0 ? 0 : ((s.$2 / max) * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.$1,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF3D425E),
                              ),
                            ),
                          ),
                          Text(
                            '${s.$2} ($percent%)',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF5A5F7A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFE9ECF4),
                          valueColor: AlwaysStoppedAnimation<Color>(s.$3),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _booksGrid(List<BookModel> books) {
    if (books.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Aucun livre trouve')),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      itemCount: books.length,
      itemBuilder: (_, i) {
        final book = books[i];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: const Color(0xFFE0E0E6),
                    width: double.infinity,
                    child: (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                        ? Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.book),
                          )
                        : const Icon(Icons.book),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF5A5F7A))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  SizedBox(height: 30, child: FilledButton.tonal(onPressed: () => _reserve(book), child: const Text('Reserver'))),
                  SizedBox(height: 30, child: OutlinedButton(onPressed: () => _borrow(book), child: const Text('Emprunter'))),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookDetailsView(book: book)));
                  },
                  child: const Text('Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _smallMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.sora(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: const Color(0xFF272662),
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF5A5F7A),
            ),
          ),
        ],
      ),
    );
  }
}
