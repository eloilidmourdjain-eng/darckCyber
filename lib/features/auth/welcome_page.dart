import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

// Import de ta page de connexion
import 'package:darck_puls/features/auth/login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  // Animations
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _pulseController;

  // Thème Cyber
  final Color kBackgroundColor = const Color(0xFF05000A); // Noir abyssal
  final Color kAccentCyan = const Color(0xFF00E5FF);
  final Color kAccentPurple = const Color(0xFF8B5CF6);
  final Color kCardBackground = const Color(0xFF131C2D);

  @override
  void initState() {
    super.initState();

    // Animation d'entrée (Glissement + Fondu) façon Apple/Vercel
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutExpo));

    // Animation du radar/statut (Clignotement)
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // --- 1. BACKGROUND GLOW (Lumières d'ambiance) ---
          Positioned(
            top: -150, left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kAccentCyan.withOpacity(0.15)),
            ),
          ),
          Positioned(
            bottom: -150, right: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kAccentPurple.withOpacity(0.15)),
            ),
          ),
          // Filtre de flou global pour le fond
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),

          // --- 2. CONTENU PRINCIPAL ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500), // Optimisé pour tablette/PC aussi
                      decoration: BoxDecoration(
                        color: kCardBackground.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 40, offset: const Offset(0, 20)),
                          BoxShadow(color: kAccentCyan.withOpacity(0.05), blurRadius: 20, spreadRadius: -5), // Glow externe
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Glassmorphism sur la carte
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // --- HEADER TERMINAL ---
                                Row(
                                  children: [
                                    Icon(CupertinoIcons.shield_lefthalf_fill, color: kAccentCyan, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "> DOCKPULSE // ENGINE CORE V1.8",
                                        style: GoogleFonts.jetBrainsMono(color: kAccentCyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white12, height: 1, thickness: 1)),

                                // --- LOGO ---
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.02),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Image.asset(
                                    'assets/logo.png',
                                    height: 100,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Icon(CupertinoIcons.waveform_path_ecg, size: 80, color: kAccentCyan), // Fallback visuel
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // --- TITRE ---
                                Text(
                                  "CONNEXION AU RÉSEAU LOCAL",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Initialisation des protocoles de sécurité et chiffrement des flux de gestion.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.blueGrey[400], fontSize: 12, height: 1.5),
                                ),
                                const SizedBox(height: 40),

                                // --- BOUTON D'ACTION PREMIUM ---
                                _buildPremiumButton(context),
                                const SizedBox(height: 32),

                                // --- FOOTER (Statuts) ---
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        _buildBlinkingDot(),
                                        const SizedBox(width: 8),
                                        Text("Status: WAITING", style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[400], fontSize: 10)),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {},
                                      child: Row(
                                        children: [
                                          Icon(CupertinoIcons.settings, color: Colors.blueGrey[400], size: 14),
                                          const SizedBox(width: 4),
                                          Text("Settings", style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[400], fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // --- LIEN INITIALISATION ---
                                GestureDetector(
                                  onTap: () {},
                                  child: Text(
                                    "Première utilisation ? Initialiser le jeton",
                                    style: TextStyle(color: kAccentCyan, fontSize: 12, fontWeight: FontWeight.w600, decoration: TextDecoration.underline, decorationColor: kAccentCyan),
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

  // --- COMPOSANT : BOUTON PREMIUM ---
  Widget _buildPremiumButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [kAccentCyan.withOpacity(0.8), const Color(0xFF1E3A8A)], begin: Alignment.centerLeft, end: Alignment.centerRight),
        boxShadow: [BoxShadow(color: kAccentCyan.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => const LoginPage()));
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "CONTINUER VERS L'AUTHENTIFICATION",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(width: 12),
              const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPOSANT : POINT CLIGNOTANT (Radar/Status) ---
  Widget _buildBlinkingDot() {
    return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orangeAccent.withOpacity(0.5 + (_pulseController.value * 0.5)),
              boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(_pulseController.value * 0.8), blurRadius: 6)],
            ),
          );
        }
    );
  }
}