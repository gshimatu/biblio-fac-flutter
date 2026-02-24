import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

class ProfileDetailsView extends StatefulWidget {
  const ProfileDetailsView({super.key});

  @override
  State<ProfileDetailsView> createState() => _ProfileDetailsViewState();
}

class _ProfileDetailsViewState extends State<ProfileDetailsView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _facultyController;
  late TextEditingController _promotionController;
  late TextEditingController _matriculeController;

  bool _isLoading = false;
  String? _errorMessage;

  // Pour l'image sélectionnée
  File? _imageFile; // pour mobile
  String? _selectedImagePath; // pour web (URL blob)

  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();

  List<String> _missingRequiredFields() {
    final missing = <String>[];
    if (_fullNameController.text.trim().isEmpty) missing.add('Nom complet');
    if (_emailController.text.trim().isEmpty) missing.add('Email');
    if (_phoneController.text.trim().isEmpty) missing.add('Telephone');
    if (_addressController.text.trim().isEmpty) missing.add('Adresse');
    if (_facultyController.text.trim().isEmpty) missing.add('Faculte');
    if (_promotionController.text.trim().isEmpty) missing.add('Promotion');
    if (_matriculeController.text.trim().isEmpty) missing.add('Matricule');
    return missing;
  }

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _fullNameController = TextEditingController(text: user.fullName);
      _emailController = TextEditingController(text: user.email);
      _phoneController = TextEditingController(text: user.phoneNumber ?? '');
      _addressController = TextEditingController(text: user.address ?? '');
      _facultyController = TextEditingController(text: user.faculty ?? '');
      _promotionController = TextEditingController(text: user.promotion ?? '');
      _matriculeController = TextEditingController(text: user.matricule ?? '');

      _fullNameController.addListener(_refreshMissingIndicators);
      _phoneController.addListener(_refreshMissingIndicators);
      _addressController.addListener(_refreshMissingIndicators);
      _facultyController.addListener(_refreshMissingIndicators);
      _promotionController.addListener(_refreshMissingIndicators);
      _matriculeController.addListener(_refreshMissingIndicators);
    } else {
      _fullNameController = TextEditingController();
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
      _addressController = TextEditingController();
      _facultyController = TextEditingController();
      _promotionController = TextEditingController();
      _matriculeController = TextEditingController();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  void _refreshMissingIndicators() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_refreshMissingIndicators);
    _phoneController.removeListener(_refreshMissingIndicators);
    _addressController.removeListener(_refreshMissingIndicators);
    _facultyController.removeListener(_refreshMissingIndicators);
    _promotionController.removeListener(_refreshMissingIndicators);
    _matriculeController.removeListener(_refreshMissingIndicators);

    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _facultyController.dispose();
    _promotionController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      if (kIsWeb) {
        setState(() {
          _selectedImagePath = pickedFile.path;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
          _selectedImagePath = null;
        });
      }
    }
  }

  /// Téléverse l'image et retourne l'URL de téléchargement.
  /// Lance une exception en cas d'échec.
  Future<String> _uploadImage(String uid) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      if (kIsWeb) {
        if (_selectedImagePath == null) throw Exception('Aucune image sélectionnée');
        final XFile pickedFile = XFile(_selectedImagePath!);
        final bytes = await pickedFile.readAsBytes();
        await ref.putData(bytes);
      } else {
        if (_imageFile == null) throw Exception('Aucune image sélectionnée');
        await ref.putFile(_imageFile!);
      }

      final downloadUrl = await ref.getDownloadURL();
      print('Image uploadée avec succès : $downloadUrl'); // LOG
      return downloadUrl;
    } catch (e) {
      print('Erreur lors de l\'upload : $e'); // LOG
      rethrow; // On relance pour que l'appelant puisse gérer
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      String? imageUrl;
      final hasNewImage = (kIsWeb && _selectedImagePath != null) || (!kIsWeb && _imageFile != null);

      if (hasNewImage) {
        try {
          imageUrl = await _uploadImage(user.uid);
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Échec de l\'upload de l\'image : $e';
              _isLoading = false;
            });
          }
          return; // On arrête la mise à jour
        }
      }

      final updatedUser = user.copyWith(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        faculty: _facultyController.text.trim().isEmpty
            ? null
            : _facultyController.text.trim(),
        promotion: _promotionController.text.trim().isEmpty
            ? null
            : _promotionController.text.trim(),
        matricule: _matriculeController.text.trim().isEmpty
            ? null
            : _matriculeController.text.trim(),
        profileImageUrl: imageUrl ?? user.profileImageUrl,
      );

      await _userService.updateUser(updatedUser);
      authProvider.setUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront effacées. Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Supprimer l'image de profil si elle existe
      if (user.profileImageUrl != null) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(user.profileImageUrl!);
          await ref.delete();
        } catch (e) {
          debugPrint('Erreur suppression image: $e');
        }
      }

      await _userService.deleteUser(user.uid);
      await authProvider.deleteAccount();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erreur lors de la suppression: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    if (user == null) return const SizedBox.shrink();
    final missingFields = _missingRequiredFields();

    // Déterminer l'image à afficher
    ImageProvider? imageProvider;
    if (_selectedImagePath != null) {
      imageProvider = NetworkImage(_selectedImagePath!);
    } else if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (user.profileImageUrl != null) {
      imageProvider = NetworkImage(user.profileImageUrl!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Mon Profil',
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
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              // Photo de profil
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFE0E0E6),
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person, size: 60, color: Color(0xFF5A5F7A))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF272662),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (missingFields.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Profil incomplet: ${missingFields.length} champ(s) obligatoire(s) manquant(s)',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF8A4B00),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: missingFields
                            .map(
                              (field) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  field,
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF8A4B00),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),

              // Champs du formulaire
              _buildField('Nom complet', _fullNameController, 'Votre nom', Icons.person),
              const SizedBox(height: 16),
              _buildField('Email', _emailController, 'email@exemple.com', Icons.email,
                  enabled: false),
              const SizedBox(height: 16),
              _buildField('Téléphone', _phoneController, '+243...', Icons.phone),
              const SizedBox(height: 16),
              _buildField('Adresse', _addressController, 'Votre adresse', Icons.home),
              const SizedBox(height: 16),
              _buildField('Faculté', _facultyController, 'Ex: FASE', Icons.school),
              const SizedBox(height: 16),
              _buildField('Promotion', _promotionController, 'Ex: L3', Icons.grade),
              const SizedBox(height: 16),
              _buildField('Matricule', _matriculeController, 'Ex: SI2024001', Icons.badge),

              const SizedBox(height: 32),

              // Bouton de mise à jour
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF272662),
                    disabledBackgroundColor: const Color(0xFF272662).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Mettre à jour',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Bouton de suppression de compte
              TextButton.icon(
                onPressed: _isLoading ? null : _deleteAccount,
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text(
                  'Supprimer mon compte',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(color: Colors.red[700]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint,
      IconData icon, {bool enabled = true, bool requiredField = true}) {
    final isMissing = requiredField && controller.text.trim().isEmpty;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF5A5F7A)),
        suffixIcon: isMissing
            ? const Icon(Icons.error_outline_rounded, color: Colors.redAccent)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF272662), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E6)),
        ),
      ),
      validator: (value) {
        if (!requiredField) return null;
        if (value == null || value.trim().isEmpty) {
          return 'Champ requis';
        }
        return null;
      },
    );
  }
}
