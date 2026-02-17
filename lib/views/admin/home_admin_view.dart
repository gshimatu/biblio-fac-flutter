import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/loan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/loan_provider.dart';
import 'manage_books_view.dart';
import 'manage_users_view.dart';
import 'manage_loans_view.dart';
import 'manage_reservations_view.dart';
import 'profile_admin_details_view.dart';

class HomeAdminView extends StatefulWidget {
  const HomeAdminView({super.key});

  @override
  State<HomeAdminView> createState() => _HomeAdminViewState();
}

class _HomeAdminViewState extends State<HomeAdminView> {
  int _selectedIndex = 0;
  bool _isDataLoaded = false;

  late final List<Widget> _pages;

  static final GlobalKey<_HomeAdminViewState> _homeAdminKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pages = [
      AdminDashboardView(key: _homeAdminKey),
      const ManageBooksView(),
      const ManageUsersView(),
      const ManageLoansView(),
      const ManageReservationsView(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDataLoaded) {
        _loadData();
        _isDataLoaded = true;
      }
    });
  }

  Future<void> _loadData() async {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    await Future.wait([bookProvider.loadBooks(), loanProvider.loadAllLoans()]);
  }

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.sora(
            color: const Color(0xFF272662),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileAdminDetailsView()),
                );
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
                      errorBuilder: (_, __, ___) {
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
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileAdminDetailsView()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF272662)),
            onPressed: () async {
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF272662),
        unselectedItemColor: const Color(0xFF5A5F7A),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Livres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Utilisateurs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Emprunts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Réservations',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard Admin';
      case 1:
        return 'Gestion des Livres';
      case 2:
        return 'Gestion des Utilisateurs';
      case 3:
        return 'Gestion des Emprunts';
      case 4:
        return 'Gestion des Réservations';
      default:
        return 'Administration';
    }
  }
}

// Widget pour le tableau de bord avec accès au parent via GlobalKey
class AdminDashboardView extends StatelessWidget {
  final GlobalKey<_HomeAdminViewState>? homeAdminKey;

  const AdminDashboardView({super.key, this.homeAdminKey});

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final loanProvider = Provider.of<LoanProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final isCompactPhone = MediaQuery.of(context).size.width < 420;

    final totalBooks = bookProvider.books.length;
    final availableBooks = bookProvider.books.where((book) => book.availableCopies > 0).length;
    final activeLoans = loanProvider.loans.where((loan) => loan.status == LoanStatus.approved).length;
    final pendingLoans = loanProvider.loans.where((loan) => loan.status == LoanStatus.pending).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF272662), Color(0xFF1D9E6C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue, ${user.fullName}!',
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Panneau d\'administration',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Statistics cards
          Text(
            'Statistiques',
            style: GoogleFonts.poppins(
              color: const Color(0xFF272662),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Total Livres',
                  value: totalBooks.toString(),
                  icon: Icons.library_books,
                  color: const Color(0xFF272662),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Disponibles',
                  value: availableBooks.toString(),
                  icon: Icons.check_circle,
                  color: const Color(0xFF1D9E6C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Emprunts Actifs',
                  value: activeLoans.toString(),
                  icon: Icons.book_online,
                  color: const Color(0xFFFFA726),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'En Attente',
                  value: pendingLoans.toString(),
                  icon: Icons.pending,
                  color: const Color(0xFFEF5350),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick actions
          Text(
            'Actions Rapides',
            style: GoogleFonts.poppins(
              color: const Color(0xFF272662),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: isCompactPhone ? 140 : 132,
            ),
            children: [
              _buildActionCard(
                context,
                title: 'Gérer Livres',
                subtitle: 'Ajouter, modifier, supprimer',
                icon: Icons.library_add,
                color: const Color(0xFF272662),
                onTap: () {
                  homeAdminKey?.currentState?._onItemTapped(1);
                },
              ),
              _buildActionCard(
                context,
                title: 'Utilisateurs',
                subtitle: 'Gérer les comptes',
                icon: Icons.people,
                color: const Color(0xFF1D9E6C),
                onTap: () {
                  homeAdminKey?.currentState?._onItemTapped(2);
                },
              ),
              _buildActionCard(
                context,
                title: 'Emprunts',
                subtitle: 'Approuver et gérer',
                icon: Icons.assignment_turned_in,
                color: const Color(0xFFFFA726),
                onTap: () {
                  homeAdminKey?.currentState?._onItemTapped(3);
                },
              ),
              _buildActionCard(
                context,
                title: 'Réservations',
                subtitle: 'Gérer les réservations',
                icon: Icons.bookmark,
                color: const Color(0xFFEF5350),
                onTap: () {
                  homeAdminKey?.currentState?._onItemTapped(4);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent activity
          if (pendingLoans > 0) ...[
            Text(
              'Emprunts en attente d\'approbation',
              style: GoogleFonts.poppins(
                color: const Color(0xFF272662),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pending_actions,
                    color: const Color(0xFFEF5350),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$pendingLoans emprunt${pendingLoans > 1 ? 's' : ''} en attente',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      homeAdminKey?.currentState?._onItemTapped(3);
                    },
                    child: Text(
                      'Voir tout',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF272662),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String value,
      required String title,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.sora(
              color: const Color(0xFF272662),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF5A5F7A),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: const Color(0xFF272662),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: const Color(0xFF5A5F7A),
                fontSize: 12,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
