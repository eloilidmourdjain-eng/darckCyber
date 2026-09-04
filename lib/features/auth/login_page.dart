import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:darck_puls/features/dashboard/dashboard_page.dart';
import 'package:darck_puls/core/models/user_role.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  UserRole _selectedRole = UserRole.simpleAdmin;
  bool _isPasswordVisible = false;
  bool _show2FAStep = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() => _show2FAStep = true);
    }
  }

  void _grantAccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Authentification sécurisée réussie !"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        // Ajout du paramètre obligatoire 'userRole' et retrait du 'const'
        builder: (context) => DashboardPage(userRole: _selectedRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned(
              top: -100,
              left: -100,
              child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                  )
              )
          ),
          Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.2)
                  )
              )
          ),
          BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent)
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
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
        color: const Color(0xFF1E293B).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.lock_shield_fill, color: Color(0xFF38BDF8), size: 60),
            const SizedBox(height: 24),
            const Text(
                "Zero Trust Network",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: Row(
                children: [
                  Expanded(child: _buildRoleButton("Admin Réseau", UserRole.simpleAdmin)),
                  Expanded(child: _buildRoleButton("Super Admin", UserRole.superAdmin)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _usernameController,
              hint: "Nom d'utilisateur",
              icon: CupertinoIcons.person_alt,
              validator: (value) => (value == null || value.trim().isEmpty) ? "Veuillez entrer un nom d'utilisateur" : null,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _passwordController,
              hint: "Mot de passe",
              icon: CupertinoIcons.lock_fill,
              isPassword: true,
              validator: (value) {
                if (value == null || value.isEmpty) return "Veuillez entrer un mot de passe";
                if (value.length < 4) return "Le mot de passe est trop court";
                return null;
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                  ),
                  elevation: 4,
                ),
                onPressed: _handleLogin,
                child: const Text(
                    "SE CONNECTER",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(String title, UserRole role) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
            borderRadius: BorderRadius.circular(8)
        ),
        child: Center(
            child: Text(
                title,
                style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF38BDF8).withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold
                )
            )
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.blueGrey),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        prefixIcon: Icon(icon, color: const Color(0xFF38BDF8)),
        suffixIcon: isPassword
            ? IconButton(
            icon: Icon(
                _isPasswordVisible ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                color: const Color(0xFF38BDF8)
            ),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }

  Widget _build2FAScreen() {
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 60,
      // Correction de la typographie jetBrainsMono (B majuscule)
      textStyle: GoogleFonts.jetBrainsMono(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF38BDF8))
      ),
    );

    return Container(
      key: const ValueKey(2),
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.shield_lefthalf_fill, color: Color(0xFF38BDF8), size: 60),
          const SizedBox(height: 24),
          const Text(
              "Vérification 2FA",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 32),
          Pinput(
            length: 6,
            defaultPinTheme: defaultPinTheme,
            onCompleted: (pin) => _grantAccess(),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => setState(() => _show2FAStep = false),
            child: const Text("Annuler", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
