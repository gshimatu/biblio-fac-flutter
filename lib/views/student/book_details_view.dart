import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../models/loan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../services/loan_service.dart';

class BookDetailsView extends StatefulWidget {
  final BookModel book;

  const BookDetailsView({super.key, required this.book});

  @override
  State<BookDetailsView> createState() => _BookDetailsViewState();
}

class _BookDetailsViewState extends State<BookDetailsView> {
  final LoanService _loanService = LoanService();
  bool _submitting = false;

  Future<void> _requestLoan() async {
    if (_submitting) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final loansProvider = Provider.of<LoanProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session invalide. Reconnectez-vous.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await loansProvider.loadUserLoans();
      final exists = loansProvider.loans.any(
        (l) =>
            l.bookId == widget.book.id &&
            (l.status == LoanStatus.pending || l.status == LoanStatus.approved),
      );

      if (exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande deja existante pour ce livre.')),
        );
        return;
      }

      await _loanService.createLoan(
        LoanModel(
          id: '',
          userId: user.uid,
          bookId: widget.book.id,
          loanDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 14)),
          returnDate: null,
          status: LoanStatus.pending,
        ),
      );
      await loansProvider.loadUserLoans();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande d\'emprunt envoyee.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la demande d\'emprunt.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Details du livre',
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
                          errorBuilder: (context, error, stackTrace) => const Icon(
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
            _buildDetailRow('Categorie', book.category),
            _buildDetailRow('Date de publication', book.publishedDate),
            _buildDetailRow('Copies totales', book.totalCopies.toString()),
            _buildDetailRow('Copies disponibles', book.availableCopies.toString()),
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
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _submitting ? null : _requestLoan,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF272662),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _submitting ? 'Envoi en cours...' : 'Demander un emprunt',
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
