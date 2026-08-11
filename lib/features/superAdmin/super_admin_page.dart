import 'dart:async';
import 'package:flutter/material.dart';

const Color kBackgroundColor = Color(0xFF0F172A);
const Color kCardColor = Color(0xFF1E293B);
const Color kAccentColor = Color(0xFF38BDF8);
const Color kPrimaryColor = Color(0xFF1E3A8A);
const Color kTextMain = Colors.white;
const Color kTextSecondary = Color(0xFF94A3B8);

const TextStyle kHeaderStyle = TextStyle(
  color: kTextMain,
  fontSize: 18,
  fontWeight: FontWeight.bold,
  letterSpacing: 0.5,
);

// Stockage global en mémoire pour la simulation des 2 super administrateurs et des mots de passe transmis
List<Map<String, String>> registeredSuperAdmins = [];
List<String> simpleAdminPasswordInbox = [];

void main() {
  runApp(const SuperAdminPage());
}

class SuperAdminPage extends StatelessWidget {
  const SuperAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DARCK_CYBER v2.5',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackgroundColor,
      ),
      home: const AuthGatePage(),
    );
  }
}

// =========================================================================
// ÉCRAN DE GESTION DES ACCÈS : INSCRIPTION OU AUTHENTIFICATION (BIOMÉTRIQUE)
// =========================================================================
class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isScanningFingerprint = false;
  bool _isScanningRetina = false;
  bool _fingerprintVerified = false;
  bool _retinaVerified = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegistrationOrLogin() {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs d'identification.", Colors.orange);
      return;
    }

    // Si aucun super admin n'est inscrit, on procède à l'inscription (limité à 2)
    if (registeredSuperAdmins.isEmpty || (registeredSuperAdmins.length < 2 && !registeredSuperAdmins.any((a) => a['username'] == username))) {
      if (registeredSuperAdmins.length >= 2) {
        _showSnackBar("Limite atteinte : Maximum 2 Super Administrateurs autorisés.", Colors.red);
        return;
      }

      setState(() {
        registeredSuperAdmins.add({"username": username, "password": password});
      });

      _showSnackBar("Inscription du Super Admin réussie ! Redirection...", Colors.green);
      _navigateToDashboard(username);
    } else {
      // Phase de Connexion avec vérification biométrique (Empreinte & Rétina)
      var admin = registeredSuperAdmins.firstWhere(
            (a) => a['username'] == username && a['password'] == password,
        orElse: () => {},
      );

      if (admin.isEmpty) {
        _showSnackBar("Identifiants incorrects.", Colors.red);
        return;
      }

      if (!_fingerprintVerified || !_retinaVerified) {
        _showSnackBar("Veuillez valider l'empreinte digitale et le scan rétinien.", Colors.redAccent);
        return;
      }

      // Transmission du mot de passe dans le dashboard du simple administrateur
      simpleAdminPasswordInbox.insert(
          0,
          "[AUTH SECRETE] Le Super Admin '$username' vient de s'authentifier. Mot de passe transmis: $password"
      );

      _showSnackBar("Authentification biométrique validée ! Mot de passe transmis au Simple Admin.", Colors.green);
      _navigateToDashboard(username);
    }
  }

  void _simulateBiometricScan() {
    setState(() {
      _isScanningFingerprint = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isScanningFingerprint = false;
        _fingerprintVerified = true;
      });
      _showSnackBar("Empreinte digitale confirmée avec succès.", Colors.cyan);

      // Lancement du scan rétinien juste après
      setState(() {
        _isScanningRetina = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _isScanningRetina = false;
          _retinaVerified = true;
        });
        _showSnackBar("Balayage rétinien confirmé avec succès.", Colors.cyan);
      });
    });
  }

  void _navigateToDashboard(String username) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardPage(superAdminName: username)),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isRegistration = registeredSuperAdmins.isEmpty || registeredSuperAdmins.length < 2;

    return Scaffold(
      body: Stack(
        children: [
          const CyberBackgroundAnimation(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kAccentColor.withValues( alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.security, size: 48, color: kAccentColor),
                    const SizedBox(height: 16),
                    Text(
                      isRegistration ? "INSCRIPTION SUPER ADMIN\n(Postes limités à 2)" : "AUTHENTIFICATION SUPER ADMIN\n(Biométrie requise)",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kTextMain, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: kTextMain),
                      decoration: InputDecoration(
                        labelText: "Nom d'utilisateur Super Admin",
                        labelStyle: const TextStyle(color: kTextSecondary, fontSize: 12),
                        filled: true,
                        fillColor: kBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: kTextMain),
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        labelStyle: const TextStyle(color: kTextSecondary, fontSize: 12),
                        filled: true,
                        fillColor: kBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!isRegistration) ...[
                      const Text("Confirmation Biométrique (Empreinte & Rétina) :", style: TextStyle(color: kTextSecondary, fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.fingerprint, size: 36, color: _fingerprintVerified ? Colors.green : Colors.orange),
                              const SizedBox(height: 4),
                              Text(_fingerprintVerified ? "Vérifié" : "Empreinte", style: TextStyle(fontSize: 10, color: _fingerprintVerified ? Colors.green : kTextSecondary)),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.remove_red_eye, size: 36, color: _retinaVerified ? Colors.green : Colors.orange),
                              const SizedBox(height: 4),
                              Text(_retinaVerified ? "Vérifié" : "Rétina", style: TextStyle(fontSize: 10, color: _retinaVerified ? Colors.green : kTextSecondary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                        onPressed: (_isScanningFingerprint || _isScanningRetina) ? null : _simulateBiometricScan,
                        icon: (_isScanningFingerprint || _isScanningRetina)
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.security, size: 18),
                        label: Text((_isScanningFingerprint || _isScanningRetina) ? "Scan biométrique en cours..." : "Lancer le scan Empreinte & Rétina"),
                      ),
                      const SizedBox(height: 20),
                    ],
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _handleRegistrationOrLogin,
                      child: Text(isRegistration ? "S'inscrire (Postes : ${registeredSuperAdmins.length}/2)" : "Se connecter"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// TABLEAU DE BORD PRINCIPAL
// =========================================================================
class DashboardPage extends StatefulWidget {
  final String superAdminName;
  const DashboardPage({super.key, required this.superAdminName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kAccentColor),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha:  0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: const Icon(Icons.security, size: 14, color: Colors.green),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "DARCK_CYBER v2.5 - SUPER ADMIN",
                style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
            onPressed: () {
              _openSimpleAdminInboxModal(context);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _openProfileModal(context),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: kAccentColor,
                child: Text("EM", style: TextStyle(color: kBackgroundColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const CyberBackgroundAnimation(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PANNEAU DE CONTRÔLE OPÉRATIONNEL", style: TextStyle(color: kTextSecondary, fontSize: 11, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text("Bienvenue, ${widget.superAdminName}", style: kHeaderStyle),
                  const SizedBox(height: 24),
                  _buildSectionTitle("📊 VUE D'ENSEMBLE SÉCURITÉ & PERFORMANCES"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard("Menaces", "1,428", Icons.block, Colors.red)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildInfoCard("vGPU / N8n", "Actifs", Icons.memory, Colors.amber)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildInfoCard("Pots de Miel", "4 Actifs", Icons.bug_report, Colors.pinkAccent)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("🚀 MODULES SUPER ADMIN AVANCÉS"),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.90,
                    children: [
                      _buildRapidAccessButton(context, "Console\nSuper Admin", Icons.admin_panel_settings, Colors.redAccent, () {
                        _verifySuperAdminAccess(context);
                      }),
                      _buildRapidAccessButton(context, "Pipeline\nn8n Automation", Icons.hub, Colors.orange, () {
                        _verifySuperAdminAccess(context);
                      }),
                      _buildRapidAccessButton(context, "Équipements\nvGPU & RAM", Icons.memory, Colors.amber, () {
                        _verifySuperAdminAccess(context);
                      }),
                      _buildRapidAccessButton(context, "Pots de Miel\n(Honeypots)", Icons.security_outlined, Colors.pinkAccent, () {
                        _verifySuperAdminAccess(context);
                      }),
                      _buildRapidAccessButton(context, "Scanner\nRéseau", Icons.network_wifi, Colors.blue, () {
                        _openNetworkScanModal(context);
                      }),
                      _buildRapidAccessButton(context, "Gestion\nCred.", Icons.vpn_key, Colors.purple, () {
                        _openCredentialsModal(context);
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("📈 ACTIVITÉS OPÉRATIONNELLES (30 JOURS)"),
                  const SizedBox(height: 12),
                  _buildMonthlyActivityCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSimpleAdminInboxModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.dashboard_customize, color: Colors.orange, size: 22),
                SizedBox(width: 10),
                Text("Dashboard Simple Admin (Boîte Mots de Passe)", style: TextStyle(color: kTextMain, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10),
            const Text("Réception en temps réel des authentifications et mots de passe transmis par le Super Admin :", style: TextStyle(color: kTextSecondary, fontSize: 12)),
            const SizedBox(height: 10),
            Expanded(
              child: simpleAdminPasswordInbox.isEmpty
                  ? const Center(child: Text("Aucun mot de passe transmis pour l'instant.", style: TextStyle(color: kTextSecondary, fontSize: 12)))
                  : ListView.builder(
                itemCount: simpleAdminPasswordInbox.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      simpleAdminPasswordInbox[index],
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verifySuperAdminAccess(BuildContext context) {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.lock_person, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text("Privilèges Super Admin", style: TextStyle(color: kTextMain, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "L'accès complet aux outils de pentesting avancés, vGPU, n8n et Pots de Miel requiert une élévation de privilèges (PIN: 2026).",
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: kTextMain),
              decoration: InputDecoration(
                labelText: "Code PIN Super Admin",
                labelStyle: const TextStyle(color: kTextSecondary, fontSize: 12),
                filled: true,
                fillColor: kBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler", style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              if (pinController.text == "2026" || pinController.text == "root") {
                _showCustomSnackBar(context, "Accès Super Admin autorisé avec succès.", Colors.green);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SuperAdminToolsPage()),
                );
              } else {
                _showCustomSnackBar(context, "Code PIN incorrect. Accès refusé.", Colors.red);
              }
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }

  void _openProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    CircleAvatar(backgroundColor: kAccentColor, child: Text("EM", style: TextStyle(color: kBackgroundColor, fontWeight: FontWeight.bold))),
                    SizedBox(width: 12),
                    Text("Profil Administrateur", style: TextStyle(color: kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: kTextSecondary), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10),
            _buildProfileInfoRow("Nom Actuel", widget.superAdminName),
            _buildProfileInfoRow("Statut", "Étudiant - Licence Pro Programmation & Réseaux"),
            _buildProfileInfoRow("Rôle Système", "Root / Super Administrateur Principal"),
            _buildProfileInfoRow("Postes Inscrits", "${registeredSuperAdmins.length} / 2 autorisés"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha:  0.2),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthGatePage()),
                        (route) => false,
                  );
                },
                child: const Text("Déconnexion / Verrouiller la session"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
          Flexible(child: Text(value, style: const TextStyle(color: kTextMain, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  void _openCredentialsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const CredentialsManagerSheet(),
    );
  }

  void _openNetworkScanModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const NetworkScanSheet(),
    );
  }

  void _showCustomSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: kCardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: kBackgroundColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(backgroundColor: kAccentColor, child: Text("EM", style: TextStyle(color: kBackgroundColor, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Text(widget.superAdminName, style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold)),
                Text("Super Admin - DarckCyber", style: TextStyle(color: kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          ListTile(title: const Text("Tableau de bord", style: TextStyle(color: kTextMain)), leading: const Icon(Icons.dashboard, color: kAccentColor), onTap: () => Navigator.pop(context)),
          ListTile(
            title: const Text("Boîte Simple Admin (Mots de passe)", style: TextStyle(color: Colors.orange)),
            leading: const Icon(Icons.dashboard_customize, color: Colors.orange),
            onTap: () {
              Navigator.pop(context);
              _openSimpleAdminInboxModal(context);
            },
          ),
          ListTile(
            title: const Text("Console Super Admin & Outils", style: TextStyle(color: Colors.redAccent)),
            leading: const Icon(Icons.admin_panel_settings, color: Colors.redAccent),
            onTap: () {
              Navigator.pop(context);
              _verifySuperAdminAccess(context);
            },
          ),
          ListTile(
            title: const Text("Déconnexion", style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthGatePage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: kTextSecondary, fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.bold));
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha:  0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRapidAccessButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: kCardColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: color.withValues( alpha: .2),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha:  0.4), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextMain, fontSize: 11, fontWeight: FontWeight.w600, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha:  0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBarDetail("Audits de vulnérabilité & Pentests", 14, 15, Colors.blue),
          const SizedBox(height: 12),
          _buildProgressBarDetail("Workflows n8n actifs", 8, 8, Colors.orange),
          const SizedBox(height: 12),
          _buildProgressBarDetail("Pots de miel (Piégeages d'attaques)", 4, 4, Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _buildProgressBarDetail(String label, int current, int max, Color color) {
    double progress = max > 0 ? (current / max) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(color: kTextMain, fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text("$current / $max", style: const TextStyle(color: kTextSecondary, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha:  0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// CONSOLE SUPER ADMIN : OUTILS AVANCÉS (PENTEST, vGPU, N8N, POTS DE MIEL)
// =========================================================================
class SuperAdminToolsPage extends StatefulWidget {
  const SuperAdminToolsPage({super.key});

  @override
  State<SuperAdminToolsPage> createState() => _SuperAdminToolsPageState();
}

class _SuperAdminToolsPageState extends State<SuperAdminToolsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cmdController = TextEditingController();

  bool _n8nRunning = true;
  bool _vgpuActive = true;

  final List<String> _terminalLogs = [
    "DarckCyber Super Admin OS Security Shell [Version 2.5.0]",
    "Modules chargés: vGPU, n8n Automation, Honeypots, Pentesting Core.",
    ""
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cmdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        iconTheme: const IconThemeData(color: Colors.redAccent),
        title: const Text("Console Super Admin & Outils Avancés", style: TextStyle(color: kTextMain, fontSize: 15, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.redAccent,
          unselectedLabelColor: kTextSecondary,
          indicatorColor: Colors.redAccent,
          tabs: const [
            Tab(icon: Icon(Icons.terminal, size: 18), text: "Terminal Shell"),
            Tab(icon: Icon(Icons.hub, size: 18), text: "Option n8n & vGPU"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.black,
                  child: ListView.builder(
                    itemCount: _terminalLogs.length,
                    itemBuilder: (context, index) {
                      return Text(
                        _terminalLogs[index],
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: kCardColor,
                child: Row(
                  children: [
                    const Text("root@darck:~# ", style: TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                    Expanded(
                      child: TextField(
                        controller: _cmdController,
                        style: const TextStyle(color: kTextMain, fontFamily: 'monospace', fontSize: 13),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: "Entrez une commande...", hintStyle: TextStyle(color: kTextSecondary)),
                        onSubmitted: (val) {
                          if (val.trim().isEmpty) return;
                          setState(() {
                            _terminalLogs.add("root@darck:~# $val");
                            _terminalLogs.add("Exécution OK.\n");
                          });
                          _cmdController.clear();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text("Moteur n8n", style: TextStyle(color: kTextMain)),
                value: _n8nRunning,
                activeThumbColor: Colors.orange,
                onChanged: (val) => setState(() => _n8nRunning = val),
              ),
              SwitchListTile(
                title: const Text("vGPU Acceleration", style: TextStyle(color: kTextMain)),
                value: _vgpuActive,
                activeThumbColor: Colors.amber,
                onChanged: (val) => setState(() => _vgpuActive = val),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// GESTIONNAIRE DE CREDENTIALS & SCANNER
// =========================================================================
class CredentialsManagerSheet extends StatelessWidget {
  const CredentialsManagerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.5,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Gestionnaire de Credentials Chiffrés", style: TextStyle(color: kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
          Divider(color: Colors.white12),
          SizedBox(height: 10),
          Text("• Root SSH Server (AES-256)\n• Anthropic Claude API Key\n• PostgreSQL Database Credentials", style: TextStyle(color: kTextSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

class NetworkScanSheet extends StatelessWidget {
  const NetworkScanSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.5,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Scanner Réseau & Ports TCP", style: TextStyle(color: kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
          Divider(color: Colors.white12),
          SizedBox(height: 10),
          Text("• Port 22 (SSH Trap): Ouvert\n• Port 80 (HTTP): Ouvert\n• Port 5678 (n8n): Actif", style: TextStyle(color: kTextSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

class CyberBackgroundAnimation extends StatefulWidget {
  const CyberBackgroundAnimation({super.key});

  @override
  State<CyberBackgroundAnimation> createState() => _CyberBackgroundAnimationState();
}

class _CyberBackgroundAnimationState extends State<CyberBackgroundAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 8), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: CyberGridPainter(animationValue: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class CyberGridPainter extends CustomPainter {
  final double animationValue;
  CyberGridPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kAccentColor.withValues(alpha:  0.06)
      ..strokeWidth = 1;

    const double gridSize = 45.0;
    double offset = animationValue * gridSize;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = offset; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.height > 0 ? size.width : 0, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CyberGridPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}