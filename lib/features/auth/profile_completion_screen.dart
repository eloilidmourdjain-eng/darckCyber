import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:darck_puls/core/models/user_role.dart';
import 'package:darck_puls/features/dashboard/dashboard_page.dart';
import 'package:darck_puls/core/local_auth_db.dart'; // 👈 La base de données

class ProfileCompletionScreen extends StatefulWidget {
  final String userEmail;
  final UserRole role;

  const ProfileCompletionScreen({super.key, required this.userEmail, required this.role});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color kCyan = const Color(0xFF00E5FF);

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); // Pour faire réaliste

  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 1. Appel à la base de données pour mettre à jour le mot de passe et valider l'onboarding
      await LocalAuthDatabase.instance.completeUserProfile(
          widget.userEmail,
          _passwordController.text.trim()
      );

      await Future.delayed(const Duration(seconds: 1)); // Petit délai UX

      if (!mounted) return;

      // 2. Redirection vers le Dashboard avec le VRAI rôle (Root ou Simple)
      Navigator.pushReplacement(context, CupertinoPageRoute(builder: (_) => MainNavigationScreen(role: widget.role)));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRoot = widget.role == UserRole.superAdmin;
    Color themeColor = isRoot ? const Color(0xFFFF2A55) : kCyan;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text("CONFIGURATION SÉCURISÉE REQUISE", style: GoogleFonts.jetBrainsMono(color: themeColor, fontSize: 14, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF131C2D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: themeColor.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle_fill, color: themeColor, size: 48),
                  const SizedBox(height: 16),
                  const Text("Changement de mot de passe obligatoire", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      isRoot
                          ? "Vous vous connectez avec le compte Root par défaut. Vous devez impérativement sécuriser l'accès avec un nouveau mot de passe."
                          : "Le Super Administrateur exige que vous configuriez votre profil avant d'accéder au réseau.",
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey[300], fontSize: 12, height: 1.4)
                  ),
                  const SizedBox(height: 32),

                  // UPLOAD PHOTO (Simulation visuelle)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(radius: 50, backgroundColor: Colors.black.withValues(alpha: 0.3), child: const Icon(CupertinoIcons.person_solid, size: 50, color: Colors.blueGrey)),
                      Container(
                        padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                        child: const Icon(CupertinoIcons.camera_fill, color: Colors.black, size: 16),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildInputField("Numéro de Téléphone (Optionnel)", CupertinoIcons.phone, _phoneController, themeColor),
                  const SizedBox(height: 16),
                  _buildInputField("Nouveau Mot de passe robuste", CupertinoIcons.lock, _passwordController, themeColor, isPassword: true),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(CupertinoIcons.check_mark_circled_solid, size: 18),
                      label: Text(_isLoading ? "SAUVEGARDE EN BDD..." : "SCELLER LE PROFIL ET ACCÉDER", style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _isLoading ? null : _saveProfile,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, IconData icon, TextEditingController controller, Color themeColor, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
      validator: (val) {
        if (isPassword && val!.length < 6) return "Le mot de passe doit faire au moins 6 caractères";
        return null;
      },
      decoration: InputDecoration(
        filled: true, fillColor: const Color(0xFF070B14),
        hintText: hint, hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: themeColor, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}