import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:darck_puls/core/models/user_role.dart';
import 'package:darck_puls/features/dashboard/dashboard_page.dart'; // Le MainNavigationScreen
import 'package:darck_puls/core/firebase_auth_service.dart'; // Import de votre service Firebase

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color kBgColor = const Color(0xFF070B14);
  final Color kRootColor = const Color(0xFFFF2A55); // Thème Root

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _recoveryKeyController = TextEditingController();

  bool _isObscure = true;
  bool _isCreating = false;

  void _createRootAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isCreating = true);

      try {
        // Création réelle du compte SuperAdmin (Root) dans Firebase Auth et Firestore
        await FirebaseAuthService.instance.provisionAdmin(
          'root_instance',
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Instance initialisée. Compte ROOT créé avec succès."),
            backgroundColor: Colors.greenAccent,
          ),
        );

        // Redirection immédiate vers le Dashboard avec le rôle SuperAdmin
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (_) => const MainNavigationScreen(role: UserRole.superAdmin),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erreur d'initialisation : $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isCreating = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          // GLOW ARRIÈRE-PLAN
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kRootColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.15),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.transparent),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF131C2D).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: kRootColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(CupertinoIcons.flame_fill, color: kRootColor, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "INITIALISATION DU SYSTÈME",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  "Création du compte Super Administrateur (ROOT)",
                                  style: TextStyle(
                                    color: kRootColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(color: Colors.white12, height: 1),
                      ),

                      Text(
                        "ATTENTION : Ce compte possède des privilèges absolus sur l'infrastructure. Les informations saisies ici seront scellées cryptographiquement.",
                        style: TextStyle(
                          color: Colors.blueGrey[300],
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField("Nom Complet", CupertinoIcons.person, _nameController),
                      const SizedBox(height: 16),
                      _buildTextField("Email Professionnel", CupertinoIcons.mail, _emailController),
                      const SizedBox(height: 16),
                      _buildTextField("Mot de Passe Maître", CupertinoIcons.lock, _passwordController, isPassword: true),
                      const SizedBox(height: 16),

                      // Clé de récupération (Simulée)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Clé de récupération (Recovery Key)",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "DP-ROOT-8842-AXX9-ZLQ1",
                              style: GoogleFonts.jetBrainsMono(
                                color: kRootColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Notez cette clé dans un endroit sûr. Elle est requise en cas de perte du mot de passe maître.",
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kRootColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isCreating
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            size: 18,
                          ),
                          label: Text(
                            _isCreating
                                ? "GÉNÉRATION DES CLÉS..."
                                : "SCELLER ET INITIALISER L'INSTANCE",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          onPressed: _isCreating ? null : _createRootAccount,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(
      String hint,
      IconData icon,
      TextEditingController controller, {
        bool isPassword = false,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _isObscure,
      style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
      validator: (val) => val!.isEmpty ? "Requis" : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF070B14),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: kRootColor, size: 18),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isObscure
                ? CupertinoIcons.eye_slash_fill
                : CupertinoIcons.eye_fill,
            color: kRootColor,
            size: 18,
          ),
          onPressed: () => setState(() => _isObscure = !_isObscure),
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: kRootColor.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: kRootColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}