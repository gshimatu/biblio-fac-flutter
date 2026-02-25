import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

enum _UserSortOption { nameAsc, nameDesc, createdDesc, loginDesc }

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key});

  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<UserModel>>? _usersSubscription;
  List<UserModel> _users = [];

  String _search = '';
  String _roleFilter = 'Tous';
  String _statusFilter = 'Tous';
  _UserSortOption _sortOption = _UserSortOption.createdDesc;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
    _initRealtimeUsers();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initRealtimeUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _usersSubscription?.cancel();
      _usersSubscription = _userService.streamAllUsers().listen(
        (users) {
          if (!mounted) return;
          setState(() {
            _users = users;
            _isLoading = false;
            _error = null;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _error = _friendlyError(error);
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<UserModel> _filteredUsers() {
    var users = _users.where((user) {
      if (_roleFilter != 'Tous' && user.role.name != _roleFilter) {
        return false;
      }
      if (_statusFilter != 'Tous') {
        final expectedActive = _statusFilter == 'Actif';
        if (user.isActive != expectedActive) return false;
      }
      if (_search.isEmpty) return true;
      return user.fullName.toLowerCase().contains(_search) ||
          user.email.toLowerCase().contains(_search) ||
          (user.matricule ?? '').toLowerCase().contains(_search) ||
          (user.faculty ?? '').toLowerCase().contains(_search);
    }).toList();

    switch (_sortOption) {
      case _UserSortOption.nameAsc:
        users.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
        break;
      case _UserSortOption.nameDesc:
        users.sort((a, b) => b.fullName.toLowerCase().compareTo(a.fullName.toLowerCase()));
        break;
      case _UserSortOption.createdDesc:
        users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _UserSortOption.loginDesc:
        users.sort((a, b) => b.lastLogin.compareTo(a.lastLogin));
        break;
    }
    return users;
  }

  Future<void> _toggleStudentActive(UserModel user) async {
    if (user.role != UserRole.student) return;
    try {
      if (user.isActive) {
        await _userService.deactivateUser(user.uid);
      } else {
        await _userService.activateUser(user.uid);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isActive ? 'Compte etudiant desactive.' : 'Compte etudiant active.',
          ),
        ),
      );
    } catch (e) {
      _showError('Mise a jour impossible: $e');
    }
  }

  Future<void> _promoteToAdmin(UserModel user) async {
    if (user.role == UserRole.admin) return;
    try {
      await _userService.updateUserRole(user.uid, UserRole.admin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur promu admin.')),
      );
    } catch (e) {
      _showError('Promotion echouee: $e');
    }
  }

  Future<void> _demoteAdmin(UserModel user) async {
    if (user.role != UserRole.admin) return;
    try {
      await _userService.updateUserRole(user.uid, UserRole.student);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role admin retire.')),
      );
    } catch (e) {
      _showError('Action echouee: $e');
    }
  }

  Future<void> _deleteAdmin(UserModel user) async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser != null && currentUser.uid == user.uid) {
      _showError('Vous ne pouvez pas supprimer votre propre compte ici.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer admin'),
        content: Text('Supprimer le compte admin ${user.fullName} ?'),
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
    if (confirmed != true) return;

    try {
      await _userService.deleteUser(user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte admin supprime.')),
      );
    } catch (e) {
      _showError('Suppression impossible: $e');
    }
  }

  Future<void> _addAdminByEmail() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un admin'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Email utilisateur existant',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
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
            child: const Text('Promouvoir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final email = controller.text.trim().toLowerCase();
    UserModel? user;
    for (final current in _users) {
      if (current.email.toLowerCase() == email) {
        user = current;
        break;
      }
    }
    if (user == null) {
      _showError('Aucun utilisateur trouve avec cet email.');
      return;
    }
    await _promoteToAdmin(user);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('permission-denied') || message.contains('PERMISSION_DENIED')) {
      return 'Acces Firestore refuse. Autorisez les droits admin dans les regles.';
    }
    return message;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers();

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
                    hintText: 'Rechercher par nom, email, matricule, faculte...',
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
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _roleFilter,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                          DropdownMenuItem(value: 'student', child: Text('Etudiants')),
                          DropdownMenuItem(value: 'admin', child: Text('Admins')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _roleFilter = value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                          DropdownMenuItem(value: 'Actif', child: Text('Actifs')),
                          DropdownMenuItem(value: 'Inactif', child: Text('Inactifs')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _statusFilter = value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<_UserSortOption>(
                        isExpanded: true,
                        initialValue: _sortOption,
                        decoration: const InputDecoration(
                          labelText: 'Trier',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: _UserSortOption.createdDesc,
                            child: Text('Date creation (recent)'),
                          ),
                          DropdownMenuItem(
                            value: _UserSortOption.loginDesc,
                            child: Text('Derniere connexion'),
                          ),
                          DropdownMenuItem(
                            value: _UserSortOption.nameAsc,
                            child: Text('Nom A-Z'),
                          ),
                          DropdownMenuItem(
                            value: _UserSortOption.nameDesc,
                            child: Text('Nom Z-A'),
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
                        onPressed: _addAdminByEmail,
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Ajouter admin'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF272662),
                        ),
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
                        onRefresh: _initRealtimeUsers,
                        child: users.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 120),
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: const Color(0xFF272662).withValues(alpha: 0.35),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'Aucun utilisateur trouve',
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
                                itemCount: users.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  final isAdmin = user.role == UserRole.admin;
                                  final roleLabel = isAdmin ? 'Admin' : 'Etudiant';
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
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      user.fullName,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.sora(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                        color: const Color(0xFF272662),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      user.email,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.poppins(
                                                        color: const Color(0xFF5A5F7A),
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                onSelected: (action) {
                                                  switch (action) {
                                                    case 'toggle':
                                                      _toggleStudentActive(user);
                                                      break;
                                                    case 'promote':
                                                      _promoteToAdmin(user);
                                                      break;
                                                    case 'demote':
                                                      _demoteAdmin(user);
                                                      break;
                                                    case 'delete_admin':
                                                      _deleteAdmin(user);
                                                      break;
                                                  }
                                                },
                                                itemBuilder: (_) {
                                                  final items = <PopupMenuEntry<String>>[];
                                                  if (!isAdmin) {
                                                    items.add(
                                                      PopupMenuItem(
                                                        value: 'toggle',
                                                        child: Text(
                                                          user.isActive
                                                              ? 'Desactiver etudiant'
                                                              : 'Activer etudiant',
                                                        ),
                                                      ),
                                                    );
                                                    items.add(
                                                      const PopupMenuItem(
                                                        value: 'promote',
                                                        child: Text('Promouvoir admin'),
                                                      ),
                                                    );
                                                  } else {
                                                    items.add(
                                                      const PopupMenuItem(
                                                        value: 'demote',
                                                        child: Text('Retirer role admin'),
                                                      ),
                                                    );
                                                    items.add(
                                                      const PopupMenuItem(
                                                        value: 'delete_admin',
                                                        child: Text('Supprimer admin'),
                                                      ),
                                                    );
                                                  }
                                                  return items;
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _badge(roleLabel, isAdmin),
                                              _badge(user.isActive ? 'Actif' : 'Inactif', user.isActive),
                                              if ((user.matricule ?? '').isNotEmpty)
                                                _chip('Matricule ${user.matricule}'),
                                              if ((user.faculty ?? '').isNotEmpty)
                                                _chip('Faculte ${user.faculty}'),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Inscrit le ${_formatDate(user.createdAt)} • '
                                            'Derniere connexion ${_formatDate(user.lastLogin)}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFF5A5F7A),
                                              fontSize: 12,
                                            ),
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

  Widget _badge(String text, bool positive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: positive
            ? const Color(0xFF1D9E6C).withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: positive ? const Color(0xFF1D9E6C) : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
