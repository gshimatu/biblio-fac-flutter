import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageUsersView extends StatelessWidget {
  const ManageUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 80,
              color: const Color(0xFF272662).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Gestion des Utilisateurs',
              style: GoogleFonts.sora(
                color: const Color(0xFF272662),
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fonctionnalité à venir :\n'
              'Ajout/suppression d\'admins, activation/désactivation des comptes étudiants.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF5A5F7A),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}