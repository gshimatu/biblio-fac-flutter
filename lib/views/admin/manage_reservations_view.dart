import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/book_model.dart';
import '../../models/reservation_model.dart';
import '../../models/user_model.dart';
import '../../services/book_service.dart';
import '../../services/reservation_service.dart';
import '../../services/user_service.dart';

enum _ReservationSortOption { recent, oldest }

class ManageReservationsView extends StatefulWidget {
  const ManageReservationsView({super.key});

  @override
  State<ManageReservationsView> createState() => _ManageReservationsViewState();
}

class _ManageReservationsViewState extends State<ManageReservationsView> {
  final ReservationService _reservationService = ReservationService();
  final BookService _bookService = BookService();
  final UserService _userService = UserService();

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<ReservationModel> _reservations = [];
  Map<String, BookModel> _booksById = {};
  Map<String, UserModel> _usersById = {};

  String _search = '';
  String _statusFilter = 'Tous';
  _ReservationSortOption _sortOption = _ReservationSortOption.recent;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _reservationService.getAllReservations(),
        _bookService.getAllBooks(),
        _userService.getAllUsers(),
      ]);

      final reservations = results[0] as List<ReservationModel>;
      final books = results[1] as List<BookModel>;
      final users = results[2] as List<UserModel>;

      if (!mounted) return;
      setState(() {
        _reservations = reservations;
        _booksById = {for (final b in books) b.id: b};
        _usersById = {for (final u in users) u.uid: u};
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ReservationModel> _filteredReservations() {
    var reservations = _reservations.where((reservation) {
      if (_statusFilter != 'Tous' && reservation.status.name != _statusFilter) {
        return false;
      }
      if (_search.isEmpty) return true;
      final user = _usersById[reservation.userId];
      final book = _booksById[reservation.bookId];
      return (user?.fullName.toLowerCase().contains(_search) ?? false) ||
          (user?.email.toLowerCase().contains(_search) ?? false) ||
          (book?.title.toLowerCase().contains(_search) ?? false) ||
          (book?.author.toLowerCase().contains(_search) ?? false);
    }).toList();

    switch (_sortOption) {
      case _ReservationSortOption.recent:
        reservations.sort((a, b) => b.reservationDate.compareTo(a.reservationDate));
        break;
      case _ReservationSortOption.oldest:
        reservations.sort((a, b) => a.reservationDate.compareTo(b.reservationDate));
        break;
    }
    return reservations;
  }

  Future<void> _fulfill(ReservationModel reservation) async {
    await _executeAction(
      action: () => _reservationService.fulfillReservation(reservation.id),
      success: 'Reservation traitee.',
    );
  }

  Future<void> _cancel(ReservationModel reservation) async {
    await _executeAction(
      action: () => _reservationService.cancelReservation(reservation.id),
      success: 'Reservation annulee.',
    );
  }

  Future<void> _executeAction({
    required Future<void> Function() action,
    required String success,
  }) async {
    try {
      await action();
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
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

  String _statusLabel(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.active:
        return 'Active';
      case ReservationStatus.cancelled:
        return 'Annulee';
      case ReservationStatus.fulfilled:
        return 'Traitee';
    }
  }

  Color _statusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.active:
        return const Color(0xFF1D9E6C);
      case ReservationStatus.cancelled:
        return Colors.red;
      case ReservationStatus.fulfilled:
        return const Color(0xFF272662);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final reservations = _filteredReservations();

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
                        value: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                          DropdownMenuItem(value: 'active', child: Text('Actives')),
                          DropdownMenuItem(value: 'fulfilled', child: Text('Traitees')),
                          DropdownMenuItem(value: 'cancelled', child: Text('Annulees')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _statusFilter = value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<_ReservationSortOption>(
                        isExpanded: true,
                        value: _sortOption,
                        decoration: const InputDecoration(
                          labelText: 'Trier',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: _ReservationSortOption.recent,
                            child: Text('Plus recentes'),
                          ),
                          DropdownMenuItem(
                            value: _ReservationSortOption.oldest,
                            child: Text('Plus anciennes'),
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
                        onRefresh: _loadData,
                        child: reservations.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 120),
                                  Icon(
                                    Icons.bookmark_outline,
                                    size: 64,
                                    color: const Color(0xFF272662).withValues(alpha: 0.35),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'Aucune reservation trouvee',
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
                                itemCount: reservations.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final reservation = reservations[index];
                                  final user = _usersById[reservation.userId];
                                  final book = _booksById[reservation.bookId];
                                  final color = _statusColor(reservation.status);

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
                                                  color: color.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(18),
                                                ),
                                                child: Text(
                                                  _statusLabel(reservation.status),
                                                  style: GoogleFonts.poppins(
                                                    color: color,
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
                                          _chip('Reserve le ${_formatDate(reservation.reservationDate)}'),
                                          const SizedBox(height: 10),
                                          if (reservation.status == ReservationStatus.active)
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                OutlinedButton(
                                                  onPressed: () => _cancel(reservation),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  child: const Text('Annuler'),
                                                ),
                                                FilledButton(
                                                  onPressed: () => _fulfill(reservation),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: const Color(0xFF272662),
                                                  ),
                                                  child: const Text('Traiter'),
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
