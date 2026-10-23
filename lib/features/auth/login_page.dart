import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import 'package:darck_puls/features/dashboard/dashboard_page.dart'; // Le MainNavigationScreen
import 'package:darck_puls/core/models/user_role.dart';

// 🚀 IMPORTS DEVSECOPS : Base de données et Onboarding
import 'package:darck_puls/core/local_auth_db.dart'; // 👈 Ton gestionnaire SQLite
import 'package:darck_puls/features/auth/profile_completion_screen.dart'; // 👈 L'écran de configuration du profil

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // États de l'authentification
  bool _isPasswordVisible = false;
  bool _show2FAStep = false;
  bool _isLoading = false;

  // L'utilisateur authentifié en mémoire (provenant de SQLite)
  Map<String, dynamic>? _authenticatedUser;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- ÉTAPE 1 : VÉRIFICATION BDD (SQLITE) ---
  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 🔐 Interrogation de la VRAIE base de données SQLite chiffrée
      final user = await LocalAuthDatabase.instance.authenticateUser(
          _usernameController.text.trim(),
          _passwordController.text
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        setState(() {
          _authenticatedUser = user;
          _show2FAStep = true; // Passage à l'étape 2FA
        });
      } else {
        // Anti-BruteForce / Enumération : Message générique
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Accès refusé. Identifiants introuvables ou compte inactif."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating
          ),
        );
      }
    }
  }

  // --- ÉTAPE 2 : VALIDATION 2FA ET ACCÈS (Zero Trust) ---
  void _grantAccess() {
    // Dans SQLite, les booléens sont stockés sous forme d'entiers (1 ou 0)
    bool isFirstLogin = _authenticatedUser!['is_first_login'] == 1;

    // Traduction de la chaîne de caractères SQLite vers l'Enum Flutter
    UserRole role = _authenticatedUser!['role'] == 'superAdmin'
        ? UserRole.superAdmin
        : UserRole.simpleAdmin;

    // DEVSECOPS : Onboarding Enforcement (Blocage si profil incomplet)
    if (isFirstLogin && role == UserRole.simpleAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil incomplet. Configuration requise."), backgroundColor: Colors.orangeAccent, behavior: SnackBarBehavior.floating)
      );

      // Ouvre l'écran obligatoire de configuration de profil
      Navigator.pushReplacement(context, CupertinoPageRoute(builder: (_) => const ProfileCompletionScreen()));
    } else {
      // Connexion standard autorisée
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.white),
              const SizedBox(width: 10),
              Text("Session chiffrée ouverte pour ${_authenticatedUser!['name']}"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Redirection vers le Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(role: role),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // GLOW BACKGROUND
          Positioned(top: -100, left: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1E3A8A).withValues(alpha: 0.3)))),
          Positioned(bottom: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00E5FF).withValues(alpha: 0.2)))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container(color: Colors.transparent)),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOutExpo,
                switchOutCurve: Curves.easeInExpo,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation), child: FadeTransition(opacity: animation, child: child));
                },
                child: _show2FAStep ? _build2FAScreen() : _buildLoginScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Container(
      key: const ValueKey(1),
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2D).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/Logo_principal.png',
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(CupertinoIcons.lock_shield_fill, color: Color(0xFF00E5FF), size: 60),
            ),
            const SizedBox(height: 24),
            const Text("Z T N A", style: TextStyle(color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 8.0)),
            const Text("Zero Trust Network Access", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),

            _buildTextField(
              controller: _usernameController,
              hint: "Email / Identifiant IAM",
              icon: CupertinoIcons.person_alt,
              validator: (value) => (value == null || value.trim().isEmpty) ? "Requis" : null,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _passwordController,
              hint: "Mot de passe",
              icon: CupertinoIcons.lock_fill,
              isPassword: true,
              validator: (value) => (value == null || value.isEmpty) ? "Requis" : null,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5)),
                  elevation: 4,
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("AUTHENTIFICATION", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.blueGrey),
        filled: true,
        fillColor: const Color(0xFF070B14),
        prefixIcon: Icon(icon, color: const Color(0xFF00E5FF), size: 18),
        suffixIcon: isPassword
            ? IconButton(icon: Icon(_isPasswordVisible ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill, color: const Color(0xFF00E5FF), size: 18), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible))
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      ),
    );
  }

  Widget _build2FAScreen() {
    final defaultPinTheme = PinTheme(
      width: 60, height: 60,
      textStyle: GoogleFonts.jetBrainsMono(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(color: const Color(0xFF070B14), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5))),
    );

    // Extraction sécurisée du rôle depuis la base de données
    bool isSuperAdmin = _authenticatedUser!['role'] == 'superAdmin';
    Color roleColor = isSuperAdmin ? const Color(0xFFFF2A55) : const Color(0xFF00E5FF);

    return Container(
      key: const ValueKey(2),
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2D).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: roleColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: roleColor.withValues(alpha: 0.1), blurRadius: 40)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/Logo_principal.png',
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(CupertinoIcons.shield_lefthalf_fill, color: roleColor, size: 60),
          ),
          const SizedBox(height: 24),
          const Text("Double Facteur Requis", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Texte dynamique selon le rôle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(
                isSuperAdmin
                    ? "Saisissez votre code Authenticator personnel (Root Access)."
                    : "Compte Admin Standard détecté.\nVeuillez demander un Token d'accès éphémère (OOB) à votre Super Administrateur.",
                textAlign: TextAlign.center,
                style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(height: 32),

          Pinput(
            length: 6,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: Colors.white))),
            onCompleted: (pin) {
              // En production : On enverrait ce PIN au serveur pour validation.
              // Ici on simule une vérification réussie :
              if (pin == "123456") {
                _grantAccess();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Token invalide ou expiré."), backgroundColor: Colors.redAccent));
              }
            },
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            icon: const Icon(CupertinoIcons.back, size: 14),
            onPressed: () => setState(() { _show2FAStep = false; _authenticatedUser = null; }),
            label: const Text("Annuler l'authentification", style: TextStyle(color: Colors.blueGrey)),
          ),
        ],
      ),
    );
  }
}