import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:darck_puls/features/superAdmin/screens/iam_management_screen.dart'; // Pour la classe SystemUser
import 'package:darck_puls/core/firebase_auth_service.dart'; // 👈 Remplacement par le service Firebase

class UserProvisioningModal extends StatefulWidget {
  final Function(SystemUser) onUserCreated;

  const UserProvisioningModal({super.key, required this.onUserCreated});

  @override
  State<UserProvisioningModal> createState() => _UserProvisioningModalState();
}

class _UserProvisioningModalState extends State<UserProvisioningModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _forceMfa = true;
  bool _isObscure = true;
  bool _isProvisioning = false; // État de chargement

  void _submit() async {
    // 1. Validation basique
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur : Tous les champs sont obligatoires."),
            backgroundColor: Colors.redAccent,
          )
      );
      return;
    }

    setState(() => _isProvisioning = true);

    // Génération d'un ID unique
    String newId = "USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

    try {
      // 2. 🚀 SAUVEGARDE DANS FIREBASE AUTH & FIRESTORE
      await FirebaseAuthService.instance.provisionAdmin(
        newId,
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      // 3. Mise à jour de l'interface graphique (L'écran derrière le modal)
      final newUser = SystemUser(
        newId,
        _nameController.text.trim(),
        _emailController.text.trim(),
        "Admin Réseau", // On force "Simple Admin" : seul le créateur originel est Root.
        true,
        "Compte fraîchement provisionné",
      );

      widget.onUserCreated(newUser);

      if (!mounted) return;
      Navigator.pop(context); // Ferme le modal avec succès

    } catch (e) {
      if (!mounted) return;
      setState(() => _isProvisioning = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Échec du provisionnement (L'email existe peut-être déjà). Erreur: $e"),
            backgroundColor: Colors.redAccent,
          )
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF131C2D).withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: const Color(0xFFFF2A55).withValues(alpha: 0.4), width: 1.5),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HEADER DU MODAL ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("PROVISIONNEMENT ADMIN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(CupertinoIcons.clear_circled_solid, color: Colors.blueGrey),
                      onPressed: () => Navigator.pop(context)
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white12, height: 1)),

              // --- FORMULAIRE ---
              const Text("Identité", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
              const SizedBox(height: 8),
              _buildInputField("Nom Complet (ex: Alice Smith)", CupertinoIcons.person, _nameController),
              const SizedBox(height: 16),

              const Text("Contact professionnel", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
              const SizedBox(height: 8),
              _buildInputField("Adresse Email", CupertinoIcons.mail, _emailController),
              const SizedBox(height: 16),

              const Text("Sécurité", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
              const SizedBox(height: 8),
              _buildInputField("Mot de passe temporaire", CupertinoIcons.lock, _passwordController, isPassword: true),
              const SizedBox(height: 16),

              // --- MFA TOGGLE ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                        child: Text("Forcer l'enregistrement MFA/2FA et Profile à la première connexion", style: TextStyle(color: Colors.greenAccent, fontSize: 11))
                    ),
                    CupertinoSwitch(
                        value: _forceMfa,
                        activeColor: Colors.greenAccent,
                        onChanged: (val) => setState(() => _forceMfa = val)
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- BOUTON DE SOUMISSION ---
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2A55),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  icon: _isProvisioning
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(CupertinoIcons.check_mark_circled_solid, size: 18),
                  label: Text(
                      _isProvisioning ? "ENREGISTREMENT FIREBASE..." : "CRÉER LE COMPTE ADMIN",
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  onPressed: _isProvisioning ? null : _submit,
                ),
              ),

              // Padding dynamique pour éviter que le clavier mobile ne cache le bouton
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET UTILITAIRE (Input Field) ---
  Widget _buildInputField(String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: const Color(0xFF070B14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1))
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _isObscure,
        style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xFF00E5FF), size: 18),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          border: InputBorder.none,
          // Bouton pour afficher/masquer le mot de passe
          suffixIcon: isPassword
              ? IconButton(
              icon: Icon(_isObscure ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill, color: const Color(0xFF00E5FF), size: 18),
              onPressed: () => setState(() => _isObscure = !_isObscure)
          )
              : null,
        ),
      ),
    );
  }
}