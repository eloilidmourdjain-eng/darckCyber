import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:darck_puls/core/models/user_role.dart';
import 'package:darck_puls/features/dashboard/dashboard_page.dart'; // Le MainNavigationScreen

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color kCyan = const Color(0xFF00E5FF);

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text("CONFIGURATION REQUISE", style: GoogleFonts.jetBrainsMono(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold)),
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
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.orangeAccent, size: 48),
                  const SizedBox(height: 16),
                  const Text("Première Connexion", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Le Super Administrateur exige que vous complétiez votre profil avant d'accéder au SOC.", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey[300], fontSize: 12, height: 1.4)),
                  const SizedBox(height: 32),

                  // UPLOAD PHOTO (Simulation)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(radius: 50, backgroundColor: Colors.black.withValues(alpha: 0.3), child: const Icon(CupertinoIcons.person_solid, size: 50, color: Colors.blueGrey)),
                      Container(
                        padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
                        child: const Icon(CupertinoIcons.camera_fill, color: Colors.black, size: 16),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildInputField("Numéro de Téléphone (+33...)", CupertinoIcons.phone),
                  const SizedBox(height: 16),
                  _buildInputField("Nouveau Mot de passe personnel", CupertinoIcons.lock, isPassword: true),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: kCyan, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(CupertinoIcons.check_mark_circled_solid, size: 18),
                      label: Text(_isLoading ? "SAUVEGARDE..." : "VALIDER ET ACCÉDER AU RÉSEAU", style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          await Future.delayed(const Duration(seconds: 2));
                          if (!context.mounted) return;
                          Navigator.pushReplacement(context, CupertinoPageRoute(builder: (_) => const MainNavigationScreen(role: UserRole.simpleAdmin)));
                        }
                      },
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

  Widget _buildInputField(String hint, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      obscureText: isPassword,
      style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
      validator: (val) => val!.isEmpty ? "Champ requis par la politique" : null,
      decoration: InputDecoration(
        filled: true, fillColor: const Color(0xFF070B14),
        hintText: hint, hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: kCyan, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}