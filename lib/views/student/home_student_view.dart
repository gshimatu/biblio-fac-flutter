import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../models/loan_model.dart';
import '../../models/reservation_model.dart';
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
    await _reservationService.cancelReservation(reservation.id);
    await _reload();
    _snack('Reservation annulee.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    final categories = <String>{'Toutes', ...books.map((b) => b.category)}.toList()..sort();
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
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF272662)),
            onPressed: () async {
              await auth.logout();
              if (mounted) Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _reload, child: _body(books, loans, categories)),
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
    final pending = loans.where((l) => l.status == LoanStatus.pending).length.toDouble();
    final approved = loans.where((l) => l.status == LoanStatus.approved).length.toDouble();
    final returned = loans.where((l) => l.status == LoanStatus.returned).length.toDouble();
    final activeRes = _reservations.where((r) => r.status == ReservationStatus.active).length.toDouble();
    final values = [pending, approved, returned, activeRes];
    final max = values.fold<double>(1, (a, b) => a > b ? a : b);

    Widget bar(String label, double value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(label, style: GoogleFonts.poppins(fontSize: 12))),
            Expanded(
              child: LinearProgressIndicator(
                value: value / max,
                minHeight: 12,
                backgroundColor: const Color(0xFFE8ECF4),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF272662)),
              ),
            ),
            const SizedBox(width: 8),
            Text('${value.toInt()}'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _smallMetric('Livres', '${books.length}'),
            _smallMetric('Reservations', '${_reservations.length}'),
            _smallMetric('Emprunts', '${loans.length}'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              bar('Demandes', pending),
              bar('Approuves', approved),
              bar('Retournes', returned),
              bar('Res. actives', activeRes),
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
                        ? Image.network(book.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.book))
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

  Widget _smallMetric(String title, String value) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 18)),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11)),
        ],
      ),
    );
  }
}
