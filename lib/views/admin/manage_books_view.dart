import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../models/google_book_model.dart';
import '../../providers/book_provider.dart';
import '../../services/google_books_service.dart';

enum _BookSortOption {
  updatedDesc,
  titleAsc,
  titleDesc,
  authorAsc,
  availableAsc,
  availableDesc,
}

enum _ApiSearchMode { title, author, isbn }

class ManageBooksView extends StatefulWidget {
  const ManageBooksView({super.key});

  @override
  State<ManageBooksView> createState() => _ManageBooksViewState();
}

class _ManageBooksViewState extends State<ManageBooksView> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _categoryFilter = 'Tous';
  _BookSortOption _sortOption = _BookSortOption.updatedDesc;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_loaded) return;
      await _reload();
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await Provider.of<BookProvider>(context, listen: false).loadBooks();
  }

  List<BookModel> _applyFilters(List<BookModel> source) {
    var books = source.where((book) {
      if (_categoryFilter != 'Tous' && book.category != _categoryFilter) {
        return false;
      }
      if (_search.isEmpty) return true;
      return book.title.toLowerCase().contains(_search) ||
          book.author.toLowerCase().contains(_search) ||
          book.isbn.toLowerCase().contains(_search) ||
          book.category.toLowerCase().contains(_search);
    }).toList();

    switch (_sortOption) {
      case _BookSortOption.updatedDesc:
        books.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case _BookSortOption.titleAsc:
        books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case _BookSortOption.titleDesc:
        books.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case _BookSortOption.authorAsc:
        books.sort((a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()));
        break;
      case _BookSortOption.availableAsc:
        books.sort((a, b) => a.availableCopies.compareTo(b.availableCopies));
        break;
      case _BookSortOption.availableDesc:
        books.sort((a, b) => b.availableCopies.compareTo(a.availableCopies));
        break;
    }
    return books;
  }

  Future<void> _openBookDialog({BookModel? existing}) async {
    final isEdit = existing != null;
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(text: existing?.title ?? '');
    final author = TextEditingController(text: existing?.author ?? '');
    final isbn = TextEditingController(text: existing?.isbn ?? '');
    final description = TextEditingController(text: existing?.description ?? '');
    final category = TextEditingController(text: existing?.category ?? '');
    final coverUrl = TextEditingController(text: existing?.coverUrl ?? '');
    final publishedDate = TextEditingController(text: existing?.publishedDate ?? '');
    final totalCopies = TextEditingController(
      text: existing != null ? existing.totalCopies.toString() : '1',
    );
    final availableCopies = TextEditingController(
      text: existing != null ? existing.availableCopies.toString() : '1',
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isEdit ? 'Modifier le livre' : 'Ajouter un livre',
            style: GoogleFonts.sora(fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildField(title, 'Titre'),
                    _buildField(author, 'Auteur'),
                    _buildField(isbn, 'ISBN'),
                    _buildField(category, 'Categorie'),
                    _buildField(publishedDate, 'Date de publication'),
                    _buildField(totalCopies, 'Total exemplaires', isNumber: true),
                    _buildField(
                      availableCopies,
                      'Exemplaires disponibles',
                      isNumber: true,
                    ),
                    _buildField(coverUrl, 'URL couverture (optionnel)', required: false),
                    _buildField(description, 'Description', maxLines: 3),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: Text(isEdit ? 'Mettre a jour' : 'Ajouter'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true || !mounted) return;

    final total = int.tryParse(totalCopies.text.trim()) ?? 0;
    var available = int.tryParse(availableCopies.text.trim()) ?? 0;
    if (total <= 0) {
      _showError('Le nombre total doit etre superieur a 0.');
      return;
    }
    if (available < 0) available = 0;
    if (available > total) available = total;

    final provider = Provider.of<BookProvider>(context, listen: false);

    try {
      final now = DateTime.now();
      if (isEdit) {
        final book = existing.copyWith(
          title: title.text.trim(),
          author: author.text.trim(),
          isbn: isbn.text.trim(),
          description: description.text.trim(),
          category: category.text.trim(),
          totalCopies: total,
          availableCopies: available,
          coverUrl: coverUrl.text.trim().isEmpty ? null : coverUrl.text.trim(),
          updatedAt: now,
        );
        await provider.updateBook(book);
      } else {
        final book = BookModel(
          id: '',
          title: title.text.trim(),
          author: author.text.trim(),
          isbn: isbn.text.trim(),
          description: description.text.trim(),
          coverUrl: coverUrl.text.trim().isEmpty ? null : coverUrl.text.trim(),
          category: category.text.trim(),
          totalCopies: total,
          availableCopies: available,
          publishedDate: publishedDate.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await provider.addBook(book);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Livre modifie.' : 'Livre ajoute.')),
      );
    } catch (e) {
      _showError('Operation echouee: $e');
    }
  }

  GoogleBookSearchType _toSearchType(_ApiSearchMode mode) {
    switch (mode) {
      case _ApiSearchMode.title:
        return GoogleBookSearchType.title;
      case _ApiSearchMode.author:
        return GoogleBookSearchType.author;
      case _ApiSearchMode.isbn:
        return GoogleBookSearchType.isbn;
    }
  }

  Future<void> _openGoogleImportDialog() async {
    final provider = Provider.of<BookProvider>(context, listen: false);
    provider.clearExternalResults();

    final queryController = TextEditingController();
    var mode = _ApiSearchMode.title;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Importer depuis Google Books',
                style: GoogleFonts.sora(fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: 720,
                child: Consumer<BookProvider>(
                  builder: (context, value, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: queryController,
                                decoration: InputDecoration(
                                  hintText: 'Recherche titre, auteur ou ISBN...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 140,
                              child: DropdownButtonFormField<_ApiSearchMode>(
                                initialValue: mode,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Type',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: _ApiSearchMode.title,
                                    child: Text('Titre'),
                                  ),
                                  DropdownMenuItem(
                                    value: _ApiSearchMode.author,
                                    child: Text('Auteur'),
                                  ),
                                  DropdownMenuItem(
                                    value: _ApiSearchMode.isbn,
                                    child: Text('ISBN'),
                                  ),
                                ],
                                onChanged: (selected) {
                                  if (selected == null) return;
                                  setDialogState(() => mode = selected);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: value.isExternalLoading
                                  ? null
                                  : () async {
                                      final query = queryController.text.trim();
                                      if (query.isEmpty) return;
                                      await provider.searchExternalBooks(
                                        query: query,
                                        type: _toSearchType(mode),
                                      );
                                    },
                              icon: const Icon(Icons.search),
                              label: const Text('Rechercher'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (value.isExternalLoading)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          )
                        else if (value.externalError != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              value.externalError!,
                              style: GoogleFonts.poppins(
                                color: Colors.red[700],
                                fontSize: 13,
                              ),
                            ),
                          )
                        else if (value.externalBooks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              'Lancez une recherche pour afficher des resultats.',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF5A5F7A),
                              ),
                            ),
                          )
                        else
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: value.externalBooks.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = value.externalBooks[index];
                                return _buildGoogleResultTile(item);
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            );
          },
        );
      },
    );

    provider.clearExternalResults();
  }

  Widget _buildGoogleResultTile(GoogleBookModel item) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE9ECF8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.coverUrl == null
                ? const Icon(Icons.menu_book_rounded, color: Color(0xFF5A5F7A))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF5A5F7A),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF272662),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.author,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF5A5F7A),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (item.isbn.isNotEmpty) _infoChip('ISBN ${item.isbn}'),
                    if (item.publishedDate.isNotEmpty)
                      _infoChip('Publie ${item.publishedDate}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _openImportEditorDialog(item),
            icon: const Icon(Icons.file_download_done),
            label: const Text('Importer'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E6C),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openImportEditorDialog(GoogleBookModel source) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(text: source.title);
    final author = TextEditingController(text: source.author);
    final isbn = TextEditingController(text: source.isbn);
    final description = TextEditingController(text: source.description);
    final category = TextEditingController(text: 'General');
    final coverUrl = TextEditingController(text: source.coverUrl ?? '');
    final publishedDate = TextEditingController(text: source.publishedDate);
    final totalCopies = TextEditingController(text: '1');
    final availableCopies = TextEditingController(text: '1');

    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Confirmer l\'import',
            style: GoogleFonts.sora(fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildField(title, 'Titre'),
                    _buildField(author, 'Auteur'),
                    _buildField(isbn, 'ISBN', required: false),
                    _buildField(category, 'Categorie'),
                    _buildField(publishedDate, 'Date de publication'),
                    _buildField(totalCopies, 'Total exemplaires', isNumber: true),
                    _buildField(
                      availableCopies,
                      'Exemplaires disponibles',
                      isNumber: true,
                    ),
                    _buildField(coverUrl, 'URL couverture (optionnel)', required: false),
                    _buildField(description, 'Description', maxLines: 3),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Importer'),
            ),
          ],
        );
      },
    );

    if (shouldImport != true || !mounted) return;

    final total = int.tryParse(totalCopies.text.trim()) ?? 0;
    var available = int.tryParse(availableCopies.text.trim()) ?? 0;
    if (total <= 0) {
      _showError('Le nombre total doit etre superieur a 0.');
      return;
    }
    if (available < 0) available = 0;
    if (available > total) available = total;

    final now = DateTime.now();
    final book = BookModel(
      id: '',
      title: title.text.trim(),
      author: author.text.trim(),
      isbn: isbn.text.trim(),
      description: description.text.trim(),
      coverUrl: coverUrl.text.trim().isEmpty ? null : coverUrl.text.trim(),
      category: category.text.trim(),
      totalCopies: total,
      availableCopies: available,
      publishedDate: publishedDate.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    try {
      await Provider.of<BookProvider>(context, listen: false)
          .importExternalBook(book);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livre importe depuis Google Books.')),
      );
    } catch (e) {
      _showError('Import impossible: $e');
    }
  }

  Future<void> _deleteBook(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le livre'),
        content: Text('Supprimer "${book.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await Provider.of<BookProvider>(context, listen: false).deleteBook(book.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livre supprime.')),
      );
    } catch (e) {
      _showError('Suppression impossible: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool required = true,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: (value) {
          if (!required) return null;
          if ((value ?? '').trim().isEmpty) {
            return '$label requis';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider>(context);
    final categories = <String>{
      'Tous',
      ...provider.books.map((e) => e.category).where((e) => e.trim().isNotEmpty),
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final books = _applyFilters(provider.books);

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
                    hintText: 'Rechercher par titre, auteur, ISBN ou categorie...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E6)),
                    ),
                    enabledBorder: OutlineInputBorder(
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
                      width: 190,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _categoryFilter,
                        decoration: const InputDecoration(
                          labelText: 'Categorie',
                          border: OutlineInputBorder(),
                        ),
                        items: categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _categoryFilter = value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<_BookSortOption>(
                        isExpanded: true,
                        initialValue: _sortOption,
                        decoration: const InputDecoration(
                          labelText: 'Trier par',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: _BookSortOption.updatedDesc,
                            child: Text('Recents'),
                          ),
                          DropdownMenuItem(
                            value: _BookSortOption.titleAsc,
                            child: Text('Titre A-Z'),
                          ),
                          DropdownMenuItem(
                            value: _BookSortOption.titleDesc,
                            child: Text('Titre Z-A'),
                          ),
                          DropdownMenuItem(
                            value: _BookSortOption.authorAsc,
                            child: Text('Auteur A-Z'),
                          ),
                          DropdownMenuItem(
                            value: _BookSortOption.availableAsc,
                            child: Text('Dispo +'),
                          ),
                          DropdownMenuItem(
                            value: _BookSortOption.availableDesc,
                            child: Text('Dispo -'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _sortOption = value);
                        },
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => _openBookDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF272662),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _openGoogleImportDialog,
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('Importer API'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: books.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 120),
                              Icon(
                                Icons.library_books_outlined,
                                size: 64,
                                color: const Color(0xFF272662).withValues(alpha: 0.35),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'Aucun livre trouve',
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
                            itemCount: books.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return Card(
                                elevation: 0.7,
                                color: Colors.white,
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
                                              book.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.sora(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF272662),
                                              ),
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (action) {
                                              if (action == 'edit') {
                                                _openBookDialog(existing: book);
                                              } else {
                                                _deleteBook(book);
                                              }
                                            },
                                            itemBuilder: (context) => const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Modifier'),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Supprimer'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${book.author} • ${book.category}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF5A5F7A),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _infoChip('ISBN ${book.isbn}'),
                                          _infoChip(
                                            'Dispo ${book.availableCopies}/${book.totalCopies}',
                                          ),
                                          _infoChip('Maj ${_formatDate(book.updatedAt)}'),
                                        ],
                                      ),
                                      if (book.description.trim().isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          book.description,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF3E425B),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
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

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF272662),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
