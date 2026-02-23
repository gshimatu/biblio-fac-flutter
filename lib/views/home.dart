import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactPhone = screenWidth < 390;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // AppBar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Image.asset(
                  'assets/images/logo-biblio_fac-2.png',
                  width: 40,
                  height: 40,
                ),
              ),
              title: Text(
                'Biblio Fac',
                style: GoogleFonts.sora(
                  color: const Color(0xFF272662),
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                if (user != null) ...[
                  // Utilisateur connecté : afficher la photo de profil cliquable
                  GestureDetector(
                    onTap: () {
                      // Rediriger vers le dashboard selon le rôle
                      final route = user.role == UserRole.admin ? '/admin' : '/student';
                      Navigator.of(context).pushReplacementNamed(route);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFE0E0E6),
                        backgroundImage: user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                        child: user.profileImageUrl == null
                            ? const Icon(Icons.person, size: 20, color: Color(0xFF5A5F7A))
                            : null,
                      ),
                    ),
                  ),
                ] else ...[
                  // Utilisateur non connecté : boutons Connexion/Inscription
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/login');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1D9E6C),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Connexion'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF272662),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Inscription'),
                  ),
                ],
                const SizedBox(width: 20),
              ],
            ),

            // Contenu principal (identique à l'original)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Hero section
                  Container(
                    constraints: const BoxConstraints(minHeight: 380),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF272662), Color(0xFF1D9E6C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26272662),
                          blurRadius: 30,
                          offset: Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.asset(
                              'assets/images/library-hero.jpg',
                              fit: BoxFit.cover,
                              opacity: const AlwaysStoppedAnimation(0.2),
                              errorBuilder: (_, __, ___) => Container(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(isCompactPhone ? 24 : 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Bienvenue sur',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Biblio Fac',
                                style: GoogleFonts.sora(
                                  color: Colors.white,
                                  fontSize: isCompactPhone ? 36 : 42,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Votre bibliothèque universitaire '
                                'accessible en un clic.',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: isCompactPhone ? 16 : 18,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: isCompactPhone ? 24 : 32),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.start,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.search_rounded),
                                    label: const Text('Explorer le catalogue'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF272662),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isCompactPhone ? 20 : 28,
                                        vertical: isCompactPhone ? 14 : 16,
                                      ),
                                      textStyle: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isCompactPhone ? 15 : 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                    ),
                                    label: const Text('En savoir plus'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isCompactPhone ? 18 : 24,
                                        vertical: isCompactPhone ? 14 : 16,
                                      ),
                                      textStyle: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isCompactPhone ? 15 : 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Section fonctionnalités
                  Text(
                    'Fonctionnalités principales',
                    style: GoogleFonts.sora(
                      color: const Color(0xFF101535),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tout ce dont vous avez besoin pour gérer vos emprunts et réservations',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF5A5F7A),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Grille de fonctionnalités
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      mainAxisExtent: isCompactPhone ? 220 : 210,
                    ),
                    children: const [
                      _FeatureCard(
                        icon: Icons.menu_book_rounded,
                        title: 'Catalogue complet',
                        description: 'Parcourez tous les ouvrages disponibles',
                        color: Color(0xFF272662),
                      ),
                      _FeatureCard(
                        icon: Icons.search_rounded,
                        title: 'Recherche avancée',
                        description: 'Par titre, auteur ou ISBN',
                        color: Color(0xFF1D9E6C),
                      ),
                      _FeatureCard(
                        icon: Icons.event_available_rounded,
                        title: 'Emprunts',
                        description: 'Réservez et suivez vos prêts',
                        color: Color(0xFF272662),
                      ),
                      _FeatureCard(
                        icon: Icons.history_rounded,
                        title: 'Historique',
                        description: 'Consultez vos anciens emprunts',
                        color: Color(0xFF1D9E6C),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Section parcours
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF0F4FF), Color(0xFFEFFAF5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF272662).withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comment ca marche ?',
                          style: GoogleFonts.sora(
                            color: const Color(0xFF272662),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _QuickInfoCard(
                          icon: Icons.search_rounded,
                          title: '1. Recherchez',
                          description: 'Trouvez un livre par titre, auteur ou categorie.',
                          color: Color(0xFF272662),
                        ),
                        const SizedBox(height: 10),
                        const _QuickInfoCard(
                          icon: Icons.bookmark_add_rounded,
                          title: '2. Reservez',
                          description: 'Placez rapidement une reservation depuis votre dashboard.',
                          color: Color(0xFF1D9E6C),
                        ),
                        const SizedBox(height: 10),
                        const _QuickInfoCard(
                          icon: Icons.assignment_turned_in_rounded,
                          title: '3. Empruntez',
                          description: 'Suivez vos demandes et vos retours en temps reel.',
                          color: Color(0xFF272662),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C1F2A44),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pourquoi Biblio Fac ?',
                          style: GoogleFonts.sora(
                            color: const Color(0xFF101535),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Une experience simple pour gagner du temps au quotidien.',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF5A5F7A),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _BenefitChip(icon: Icons.bolt_rounded, label: 'Rapide'),
                            _BenefitChip(icon: Icons.devices_rounded, label: 'Multi-plateforme'),
                            _BenefitChip(icon: Icons.lock_rounded, label: 'Securise'),
                            _BenefitChip(icon: Icons.auto_graph_rounded, label: 'Suivi clair'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Carte de fonctionnalité réutilisable
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isCompactPhone = MediaQuery.of(context).size.width < 390;

    return Container(
      padding: EdgeInsets.all(isCompactPhone ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C1F2A44),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isCompactPhone ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isCompactPhone ? 24 : 28),
          ),
          SizedBox(height: isCompactPhone ? 12 : 16),
          Text(
            title,
            style: GoogleFonts.sora(
              color: const Color(0xFF101535),
              fontWeight: FontWeight.w700,
              fontSize: isCompactPhone ? 15 : 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(
              color: const Color(0xFF5A5F7A),
              fontSize: isCompactPhone ? 12 : 13,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  const _QuickInfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF101535),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF5A5F7A),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF272662)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF272662),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

