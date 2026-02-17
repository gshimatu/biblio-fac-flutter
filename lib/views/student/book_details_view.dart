import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/book_model.dart';

class BookDetailsView extends StatelessWidget {
  final BookModel book;

  const BookDetailsView({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Détails du livre',
          style: GoogleFonts.sora(
            color: const Color(0xFF272662),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF272662)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  width: 150,
                  color: const Color(0xFFE0E0E6),
                  child: (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.book,
                            size: 60,
                            color: Color(0xFF5A5F7A),
                          ),
                        )
                      : const Icon(
                          Icons.book,
                          size: 60,
                          color: Color(0xFF5A5F7A),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              book.title,
              style: GoogleFonts.sora(
                color: const Color(0xFF272662),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Par ${book.author}',
              style: GoogleFonts.poppins(
                color: const Color(0xFF5A5F7A),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('ISBN', book.isbn),
            _buildDetailRow('Catégorie', book.category),
            _buildDetailRow('Date de publication', book.publishedDate),
            _buildDetailRow('Copies totales', book.totalCopies.toString()),
            _buildDetailRow(
              'Copies disponibles',
              book.availableCopies.toString(),
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: GoogleFonts.poppins(
                color: const Color(0xFF272662),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.description.isEmpty
                  ? 'Aucune description disponible'
                  : book.description,
              style: GoogleFonts.poppins(
                color: const Color(0xFF5A5F7A),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Bouton factice
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité d\'emprunt à venir'),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF272662),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Demander un emprunt',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                color: const Color(0xFF272662),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: const Color(0xFF5A5F7A),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
