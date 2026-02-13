import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageBooksView extends StatelessWidget {
  const ManageBooksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gérer les Livres',
          style: GoogleFonts.sora(
            color: Color(0xFF272662),
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF272662)),
      ),
      body: const Center(
        child: Text('Gestion des livres - Fonctionnalité à implémenter'),
      ),
    );
  }
}