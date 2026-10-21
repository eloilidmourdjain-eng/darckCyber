import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:darck_puls/features/superAdmin/screens/iam_management_screen.dart';

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

  void _submit() {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) return;

    final newUser = SystemUser(
      "USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
      _nameController.text,
      _emailController.text,
      "Admin Réseau", // On force "Simple Admin" par sécurité (un seul Root)
      true,
      "Compte fraîchement provisionné",
    );

    widget.onUserCreated(newUser);
    Navigator.pop(context); // Ferme le modal
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("PROVISIONNEMENT ADMIN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(CupertinoIcons.clear_circled_solid, color: Colors.blueGrey), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white12, height: 1)),

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
              _buildInputField("Mot de passe temporaire", CupertinoIcons.lock, _passwordController, isObscure: true),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(child: Text("Forcer l'enregistrement MFA/2FA à la première connexion", style: TextStyle(color: Colors.greenAccent, fontSize: 11))),
                    CupertinoSwitch(value: _forceMfa, activeColor: Colors.greenAccent, onChanged: (val) => setState(() => _forceMfa = val)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2A55), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(CupertinoIcons.check_mark_circled_solid, size: 18),
                  label: const Text("CRÉER LE COMPTE ADMIN", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _submit,
                ),
              ),
              // Padding pour le clavier virtuel sur mobile
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, IconData icon, TextEditingController controller, {bool isObscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF070B14), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xFF00E5FF), size: 18),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          border: InputBorder.none,
        ),
      ),
    );
  }
}