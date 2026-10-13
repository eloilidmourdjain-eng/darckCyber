import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:darck_puls/features/auth/login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  // --- ANIMATIONS ---
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _bgLogoController;
  late AnimationController _pulseController;

  // --- THÈME CYBER PREMIUM ---
  final Color kBackgroundColor = const Color(0xFF05000A);
  final Color kAccentCyan = const Color(0xFF00E5FF);
  final Color kAccentPurple = const Color(0xFF8B5CF6);
  final Color kCardBackground = const Color(0xFF131C2D);

  // Choix de l'architecture réseau
  int _selectedArchitecture = 0; // 0 = None, 1 = Edge Local, 2 = SDN Core

  @override
  void initState() {
    super.initState();
    _bgLogoController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutExpo));

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _bgLogoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --- DEVSECOPS : CONNEXION AU SERVEUR CORE ---
  void _showCoreConnectionDialog() {
    showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.8),
        builder: (context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AlertDialog(
              backgroundColor: kCardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: kAccentPurple.withValues(alpha: 0.5))),
              title: Row(
                children: [
                  Icon(CupertinoIcons.cloud_fill, color: kAccentPurple),
                  const SizedBox(width: 10),
                  Text("CONNEXION AU CORE", style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Saisissez les coordonnées de votre contrôleur Dark Pulse distant (SDN).", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 20),
                  _buildSecureInputField("URL du Contrôleur (https://...)", CupertinoIcons.link),
                  const SizedBox(height: 12),
                  _buildSecureInputField("Token API / JWT", CupertinoIcons.lock_shield, isObscure: true),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.lock_fill, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 8),
                      Expanded(child: Text("La connexion sera chiffrée de bout en bout (TLS 1.3).", style: TextStyle(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 10))),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.blueGrey))),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: kAccentPurple, foregroundColor: Colors.white),
                  icon: const Icon(CupertinoIcons.bolt_fill, size: 16),
                  label: const Text("INITIALISER", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, CupertinoPageRoute(builder: (context) => const LoginPage()));
                  },
                )
              ],
            ),
          );
        }
    );
  }

  Widget _buildSecureInputField(String hint, IconData icon, {bool isObscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF070B14), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: TextField(
        obscureText: isObscure,
        style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.blueGrey[400], size: 18),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // --- ACTIONS DE NAVIGATION ---
  void _proceedToLogin() {
    if (_selectedArchitecture == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez sélectionner une architecture de déploiement."), backgroundColor: Colors.orangeAccent));
      return;
    }

    if (_selectedArchitecture == 1) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => const LoginPage()));
    } else if (_selectedArchitecture == 2) {
      _showCoreConnectionDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // 1. BACKGROUND GLOW (Lumières d'ambiance)
          Positioned(top: -150, left: -100, child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: kAccentCyan.withValues(alpha: 0.10)))),
          Positioned(bottom: -150, right: -100, child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: kAccentPurple.withValues(alpha: 0.10)))),

          // 2. LOGO GÉANT LÉVITANT EN ARRIÈRE-PLAN
          Positioned.fill(
            child: AnimatedBuilder(
                animation: _bgLogoController,
                builder: (context, child) {
                  final dy = math.sin(_bgLogoController.value * 2 * math.pi) * 30;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Opacity(
                      opacity: 0.04, // Filigrane très léger
                      child: Center(
                        child: Image.asset('assets/Logo_principal.png', width: 600, height: 600, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(CupertinoIcons.shield_lefthalf_fill, size: 600, color: Colors.white)),
                      ),
                    ),
                  );
                }
            ),
          ),

          // Filtre de verre global
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: Container(color: Colors.transparent)),

          // 3. UI PRINCIPALE (CARTE EN VERRE)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 550),
                      decoration: BoxDecoration(
                        color: kCardBackground.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 40, offset: const Offset(0, 20))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // --- HEADER TERMINAL ---
                                Row(
                                  children: [
                                    Icon(CupertinoIcons.shield_lefthalf_fill, color: kAccentCyan, size: 16),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text("> DOCKPULSE // ARCHITECTURE SETUP", style: GoogleFonts.jetBrainsMono(color: kAccentCyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white12, height: 1, thickness: 1)),

                                // --- LOGO CENTRAL (L'ANCIEN CODE RÉINTÉGRÉ ICI) ---
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.02),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                      boxShadow: [BoxShadow(color: kAccentCyan.withValues(alpha: 0.1), blurRadius: 20)],
                                    ),
                                    child: Image.asset(
                                      'assets/Logo_principal.png',
                                      height: 80, // Taille ajustée pour ne pas prendre toute la place
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Icon(CupertinoIcons.waveform_path_ecg, size: 60, color: kAccentCyan),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // --- TITRES ---
                                Text("SÉLECTIONNEZ L'ARCHITECTURE", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                const SizedBox(height: 8),
                                Text("Choisissez le mode de fonctionnement de la sonde de sécurité.", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
                                const SizedBox(height: 32),

                                // --- SÉLECTEUR D'ARCHITECTURE ---
                                _buildArchitectureCard(
                                  id: 1,
                                  title: "MODE LOCAL (EDGE COMPUTE)",
                                  desc: "Analyse autonome (SOHO/PAN). L'application utilise la puce réseau du terminal pour scanner le Wi-Fi.",
                                  icon: Icons.router, //
                                  color: kAccentCyan,
                                ),
                                const SizedBox(height: 16),
                                _buildArchitectureCard(
                                  id: 2,
                                  title: "MODE ENTREPRISE (SDN CORE)",
                                  desc: "L'application se connecte à un serveur distant pour piloter une infrastructure multi-sites.",
                                  icon: CupertinoIcons.cloud_fill,
                                  color: kAccentPurple,
                                ),
                                const SizedBox(height: 40),

                                // --- BOUTON DE VALIDATION ---
                                Container(
                                  width: double.infinity, height: 55,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(colors: [_selectedArchitecture == 0 ? Colors.blueGrey : (_selectedArchitecture == 1 ? kAccentCyan : kAccentPurple), const Color(0xFF1E3A8A)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                    boxShadow: _selectedArchitecture != 0 ? [BoxShadow(color: (_selectedArchitecture == 1 ? kAccentCyan : kAccentPurple).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))] : [],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: _proceedToLogin,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text("INITIALISER LE SYSTÈME", style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                          const SizedBox(width: 12),
                                          const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CARTE DE SÉLECTION D'ARCHITECTURE ---
  Widget _buildArchitectureCard({required int id, required String title, required String desc, required IconData icon, required Color color}) {
    bool isSelected = _selectedArchitecture == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedArchitecture = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFF070B14).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.white.withValues(alpha: 0.05), width: isSelected ? 2.0 : 1.0),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20)] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Icon(icon, color: isSelected ? color : Colors.blueGrey, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.blueGrey[300], fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(desc, style: TextStyle(color: isSelected ? Colors.white70 : Colors.blueGrey[500], fontSize: 11, height: 1.4)),
                ],
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.check_mark_circled_solid, color: color, size: 24),
              )
          ],
        ),
      ),
    );
  }
}