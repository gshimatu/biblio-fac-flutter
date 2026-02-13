import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/loan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/loan_provider.dart';
import 'manage_books_view.dart';

class HomeAdminView extends StatefulWidget {
  const HomeAdminView({super.key});

  @override
  State<HomeAdminView> createState() => _HomeAdminViewState();
}

class _HomeAdminViewState extends State<HomeAdminView> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    await Future.wait([bookProvider.loadBooks(), loanProvider.loadAllLoans()]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    final user = authProvider.currentUser;
    // Redirection si utilisateur non connecté
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalBooks = bookProvider.books.length;
    final availableBooks = bookProvider.books.where((book) => book.availableCopies > 0).length;
    final activeLoans = loanProvider.loans.where((loan) => loan.status == LoanStatus.approved).length;
    final pendingLoans = loanProvider.loans.where((loan) => loan.status == LoanStatus.pending).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Administration - Biblio Fac',
          style: GoogleFonts.sora(
            color: const Color(0xFF272662),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFF272662)),
            onPressed: () {
              // TODO: Navigate to profile
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
        child: SingleChildScrollView(
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
                      title: 'Total Livres',
                      value: totalBooks.toString(),
                      icon: Icons.library_books,
                      color: const Color(0xFF272662),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
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
                      title: 'Emprunts Actifs',
                      value: activeLoans.toString(),
                      icon: Icons.book_online,
                      color: const Color(0xFFFFA726),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
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
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildActionCard(
                    title: 'Gérer Livres',
                    subtitle: 'Ajouter, modifier, supprimer',
                    icon: Icons.library_add,
                    color: const Color(0xFF272662),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ManageBooksView()),
                      );
                    },
                  ),
                  _buildActionCard(
                    title: 'Utilisateurs',
                    subtitle: 'Gérer les comptes',
                    icon: Icons.people,
                    color: const Color(0xFF1D9E6C),
                    onTap: () {
                      // TODO: Navigate to user management
                    },
                  ),
                  _buildActionCard(
                    title: 'Emprunts',
                    subtitle: 'Approuver et gérer',
                    icon: Icons.assignment_turned_in,
                    color: const Color(0xFFFFA726),
                    onTap: () {
                      // TODO: Navigate to loan management
                    },
                  ),
                  _buildActionCard(
                    title: 'Rapports',
                    subtitle: 'Statistiques détaillées',
                    icon: Icons.analytics,
                    color: const Color(0xFFEF5350),
                    onTap: () {
                      // TODO: Navigate to reports
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
                  child: Column(
                    children: [
                      Row(
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
                              // TODO: Navigate to pending loans
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
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String title,
    required IconData icon,
    required Color color,
  }) {
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
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
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

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: const Color(0xFF272662),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: const Color(0xFF5A5F7A),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}