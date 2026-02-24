import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _facultyController = TextEditingController();
  final _promotionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _authController = AuthController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _matriculeController.dispose();
    _facultyController.dispose();
    _promotionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _matriculeController.text.isEmpty ||
        _facultyController.text.isEmpty ||
        _promotionController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authController.registerStudent(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        matricule: _matriculeController.text.trim(),
        faculty: _facultyController.text.trim(),
        promotion: _promotionController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Inscription reussie. Votre compte est en attente d\'activation par la bibliotheque.',
            ),
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  icon: const Icon(Icons.home_rounded),
                  label: Text(
                    'Accueil',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF272662),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              height: 230,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF272662), Color(0xFF39409A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -45,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 88,
              left: -35,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_rounded, color: Colors.white, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          'Compte etudiant',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Inscription',
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Creez votre compte etudiant Biblio Fac',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF272662).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.how_to_reg_rounded, color: Color(0xFF272662)),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Informations du compte',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF272662),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.22)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline_rounded, color: Colors.red[700], size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.poppins(
                                      color: Colors.red[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildField(
                          label: 'Nom complet',
                          controller: _fullNameController,
                          hint: 'Musekedi Abuyaba',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Adresse e-mail',
                          controller: _emailController,
                          hint: 'musekedi@gmail.com',
                          icon: Icons.mail_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Mot de passe',
                          controller: _passwordController,
                          hint: '********',
                          icon: Icons.lock_outline_rounded,
                          obscure: true,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Numero d\'etudiant',
                          controller: _matriculeController,
                          hint: 'SI2024001',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Faculte',
                          controller: _facultyController,
                          hint: 'FASE',
                          icon: Icons.account_balance_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Promotion',
                          controller: _promotionController,
                          hint: 'L3',
                          icon: Icons.school_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Telephone',
                          controller: _phoneController,
                          hint: '+24390236741',
                          icon: Icons.phone_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Adresse',
                          controller: _addressController,
                          hint: '123 Rue de la Paix',
                          icon: Icons.home_outlined,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _handleRegister,
                            icon: _isLoading
                                ? const SizedBox.shrink()
                                : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF272662),
                              disabledBackgroundColor: const Color(0xFF272662).withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            label: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'S\'inscrire',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: 'Vous avez deja un compte ? ',
                              style: GoogleFonts.poppins(color: const Color(0xFF5A5F7A), fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Connectez-vous',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF1D9E6C),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.of(context).pushReplacementNamed('/login');
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: const Color(0xFF272662),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: const Color(0xFF5A5F7A)),
            prefixIcon: Icon(icon, color: const Color(0xFF5A5F7A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF272662), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
