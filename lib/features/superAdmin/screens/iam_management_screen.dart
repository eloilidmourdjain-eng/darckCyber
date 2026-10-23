import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:darck_puls/features/superAdmin/screens/user_provisioning_modal.dart'; // Modal de création

// --- MODÈLES DE DONNÉES (IAM) ---
class SystemUser {
  final String id;
  final String name;
  final String email;
  final String role; // "Super Admin" ou "Admin Réseau"
  bool isActive;
  final String lastLogin;

  SystemUser(this.id, this.name, this.email, this.role, this.isActive, this.lastLogin);
}

class AuditLog {
  final String timestamp;
  final String user;
  final String action;
  final String target;
  final String ipContext;

  AuditLog(this.timestamp, this.user, this.action, this.target, this.ipContext);
}

class IamManagementScreen extends StatefulWidget {
  const IamManagementScreen({super.key});

  @override
  State<IamManagementScreen> createState() => _IamManagementScreenState();
}

class _IamManagementScreenState extends State<IamManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color kBgColor = const Color(0xFF070B14);
  final Color kCardColor = const Color(0xFF131C2D);
  final Color kRootColor = const Color(0xFFFF2A55);
  final Color kCyan = const Color(0xFF00E5FF);

  // Fausse base de données des utilisateurs
  final List<SystemUser> _users = [
    SystemUser("USR-001", "Éloilid Mourdjain", "eloilid@darkpulse.com", "Super Admin", true, "Il y a 2 min"),
    SystemUser("USR-002", "John Doe (SOC)", "j.doe@darkpulse.com", "Admin Réseau", true, "Hier, 14:02"),
    SystemUser("USR-003", "Alice Smith (NOC)", "a.smith@darkpulse.com", "Admin Réseau", false, "Jamais connecté"), // Suspendu
  ];

  // Fausse base de données d'Audit (Les faits et gestes)
  final List<AuditLog> _auditLogs = [
    AuditLog("10:45:01", "j.doe@darkpulse.com", "Bannissement IP (UFW)", "192.168.1.109", "Depuis 10.0.0.5"),
    AuditLog("09:12:44", "j.doe@darkpulse.com", "Exécution QoS (Throttling)", "MAC: AA:BB:CC:DD", "Depuis 10.0.0.5"),
    AuditLog("08:00:00", "eloilid@darkpulse.com", "Création de compte", "a.smith@darkpulse.com", "Console Root"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openProvisioningModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserProvisioningModal(
        onUserCreated: (newUser) {
          setState(() {
            _users.add(newUser);
            _auditLogs.insert(0, AuditLog("À l'instant", "eloilid@darkpulse.com", "Création de compte", newUser.email, "Console Root"));
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('Identity & Access Management (IAM)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kRootColor,
          labelColor: kRootColor,
          unselectedLabelColor: Colors.blueGrey[600],
          tabs: const [
            Tab(icon: Icon(CupertinoIcons.group_solid), text: "Gestion Utilisateurs"),
            Tab(icon: Icon(CupertinoIcons.eye_solid), text: "Audit (Faits & Gestes)"),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildUsersTab(),
            _buildAuditTab(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ONGLET 1 : GESTION DES UTILISATEURS & 2FA (Version Unifiée)
  // ==========================================
  Widget _buildUsersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 🚀 GÉNÉRATEUR DE TOKENS (OOB MFA) ---
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kCyan.withValues(alpha: 0.4)),
            boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.1), blurRadius: 20)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kCyan.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(CupertinoIcons.lock_shield_fill, color: kCyan, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("GÉNÉRATEUR DE TOKENS (OOB MFA)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    Text("Générez un code temporaire pour débloquer la session d'un administrateur à distance.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kCyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                icon: const Icon(CupertinoIcons.arrow_2_circlepath, size: 18),
                label: const Text("Générer (60s)", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: kCardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kCyan)),
                      title: const Text("Token d'Authentification Généré", style: TextStyle(color: Colors.white, fontSize: 16)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Communiquez ce code à l'administrateur. Il expirera dans 60 secondes.", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCyan)),
                            child: Text("123456", style: GoogleFonts.jetBrainsMono(color: kCyan, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8.0)),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer", style: TextStyle(color: Colors.blueGrey))),
                      ],
                    ),
                  );
                },
              )
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Opérateurs Système", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Gérez les accès et les sessions des administrateurs.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kRootColor, foregroundColor: Colors.white),
                icon: const Icon(CupertinoIcons.person_add_solid, size: 16),
                label: const Text("Provisionner", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _openProvisioningModal,
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              final isRoot = user.role == "Super Admin";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: user.isActive ? Colors.white.withValues(alpha: 0.05) : Colors.redAccent.withValues(alpha: 0.3))
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isRoot ? kRootColor.withValues(alpha: 0.2) : kCyan.withValues(alpha: 0.2),
                      child: Text(user.name.substring(0, 2).toUpperCase(), style: TextStyle(color: isRoot ? kRootColor : kCyan, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: (isRoot ? kRootColor : kCyan).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(user.role, style: TextStyle(color: isRoot ? kRootColor : kCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(user.email, style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[400], fontSize: 11)),
                          const SizedBox(height: 4),
                          Text("Dernière activité : ${user.lastLogin}", style: TextStyle(color: Colors.blueGrey[600], fontSize: 10)),
                        ],
                      ),
                    ),
                    if (!isRoot) // Le Super Admin ne peut pas se bloquer lui-même
                      CupertinoSwitch(
                        value: user.isActive,
                        activeColor: Colors.greenAccent,
                        onChanged: (val) {
                          setState(() {
                            user.isActive = val;
                            _auditLogs.insert(0, AuditLog("À l'instant", "eloilid@darkpulse.com", val ? "Restauration d'accès" : "Révocation d'accès (Kill Session)", user.email, "Console Root"));
                          });
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  // ==========================================
  // ONGLET 2 : AUDIT DES FAITS ET GESTES (WORM)
  // ==========================================
  Widget _buildAuditTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _auditLogs.length,
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                child: Text(log.timestamp, style: GoogleFonts.jetBrainsMono(color: kCyan, fontSize: 10)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text("Cible : ${log.target}", style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
                    const SizedBox(height: 2),
                    Text("Par : ${log.user} (${log.ipContext})", style: TextStyle(color: Colors.blueGrey[600], fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}