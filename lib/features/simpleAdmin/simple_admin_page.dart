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

class SimpleAdminPage extends StatefulWidget {
  const SimpleAdminPage({super.key});

  @override
  State<SimpleAdminPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<SimpleAdminPage> {
  // Liste dynamique des outils intégrés (incluant N8n et autres outils ajoutables)
  final List<Map<String, dynamic>> _dynamicTools = [
    {"title": "N8n Automation", "subtitle": "Instance Docker Locale", "icon": Icons.hub, "color": Colors.orange},
    {"title": "Portainer Daemons", "subtitle": "Gestion Conteneurs", "icon": Icons.dns, "color": Colors.blue},
    {"title": "Grafana Monitor", "subtitle": "Métriques & Logs temps réel", "icon": Icons.insights, "color": Colors.amber},
  ];

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
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: const Icon(Icons.security, size: 14, color: Colors.green),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "DARCK_CYBER v2.5 - ENTERPRISE",
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
              _showCustomSnackBar(context, "Aucune nouvelle alerte critique MFA/SSO", Colors.orange);
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
                  const Text("PANNEAU D'ADMINISTRATION CENTRALISÉ", style: TextStyle(color: kTextSecondary, fontSize: 11, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  const Text("Bienvenue, Éloilid Mourdjain", style: kHeaderStyle),
                  const SizedBox(height: 24),
                  _buildSectionTitle("📊 VUE D'ENSEMBLE CONFORMITÉ & SÉCURITÉ"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard("MFA Enrôlés", "98.4%", Icons.verified_user, Colors.green)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildInfoCard("Passkeys", "Actifs", Icons.fingerprint, kAccentColor)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildInfoCard("Conformité", "ISO/NIS2", Icons.policy, Colors.purple)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("🚀 MODULES & OUTILS DE GESTION"),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.95,
                    children: [
                      _buildRapidAccessButton(context, "Sécurité\nAvancée 2FA", Icons.lock_outline, kPrimaryColor, () {
                        _openAdvanced2faModal(context);
                      }),
                      _buildRapidAccessButton(context, "Autorisation\nde Tâches", Icons.rule, Colors.teal, () {
                        _openTaskAuthorizationModal(context);
                      }),
                      _buildRapidAccessButton(context, "Gestion\nLogs & Audit", Icons.text_snippet, Colors.orange, () {
                        _openLogsModal(context);
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("🧩 OUTILS INTÉGRÉS & EXTERNES (N8N, ETC.)"),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: kAccentColor, padding: EdgeInsets.zero),
                        onPressed: () => _showAddToolDialog(context),
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text("Ajouter un outil", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _dynamicTools.length,
                    itemBuilder: (context, index) {
                      final tool = _dynamicTools[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kCardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: (tool["color"] as Color).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(tool["icon"] as IconData, color: tool["color"] as Color, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tool["title"]!, style: const TextStyle(color: kTextMain, fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(tool["subtitle"]!, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.launch, size: 16, color: kAccentColor),
                              onPressed: () {
                                _showCustomSnackBar(context, "Connexion et initialisation de ${tool["title"]}...", tool["color"] as Color);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("📈 ACTIVITÉS & AUDIT DE CONFORMITÉ"),
                  const SizedBox(height: 12),
                  _buildMonthlyActivityCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("⚙️ ACTIONS ADMINISTRATEUR PRINCIPALES"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildAdminAction(context, "Politiques 2FA", Icons.security, kPrimaryColor, () {
                        _openAdvanced2faModal(context);
                      })),
                      const SizedBox(width: 10),
                      Expanded(child: _buildAdminAction(context, "Tâches", Icons.rule, Colors.teal, () {
                        _openTaskAuthorizationModal(context);
                      })),
                      const SizedBox(width: 10),
                      Expanded(child: _buildAdminAction(context, "Profil", Icons.person_outline, Colors.teal, () {
                        _openProfileModal(context);
                      })),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODALE D'AJOUT D'OUTILS PERSONNALISÉS (ex: N8n, etc.) ---
  void _showAddToolDialog(BuildContext parentContext) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Ajouter un Nouvel Outil / Service", style: TextStyle(color: kTextMain, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: kTextMain),
              decoration: InputDecoration(
                labelText: "Nom de l'outil (ex: N8n Cloud, Prometheus)",
                labelStyle: const TextStyle(color: kTextSecondary, fontSize: 12),
                filled: true,
                fillColor: kBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: kTextMain),
              decoration: InputDecoration(
                labelText: "Description / Endpoint / URL",
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Annuler", style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccentColor, foregroundColor: kBackgroundColor),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _dynamicTools.add({
                    "title": nameController.text,
                    "subtitle": descController.text.isNotEmpty ? descController.text : "Service intégré personnalisé",
                    "icon": Icons.extension,
                    "color": Colors.teal,
                  });
                });
                Navigator.pop(dialogContext);
                _showCustomSnackBar(parentContext, "Outil ajouté au tableau de bord avec succès.", Colors.green);
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  // --- MODALE DE GESTION DES TÂCHES (Autorisation de tâches) ---
  void _openTaskAuthorizationModal(BuildContext parentContext) {
    final List<Map<String, dynamic>> pendingTasks = [
      {"id": "TSK-01", "task": "Déploiement production conteneur backend v2.4", "requester": "Éloilid Mourdjain", "risk": "Élevé"},
      {"id": "TSK-02", "task": "Modification des règles de filtrage pare-feu WAN", "requester": "Équipe Sécurité", "risk": "Critique"},
      {"id": "TSK-03", "task": "Rotation automatique des clés JWT & Secrets API", "requester": "Daemon Système", "risk": "Modéré"},
    ];

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: kCardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(sheetContext).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rule, color: Colors.teal, size: 22),
                      SizedBox(width: 10),
                      Text("Centre d'Autorisation de Tâches", style: TextStyle(color: kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, color: kTextSecondary), onPressed: () => Navigator.pop(sheetContext)),
                ],
              ),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),
              const Text("Validez ou rejetez les demandes d'exécution critique nécessitant une approbation administrateur :", style: TextStyle(color: kTextSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: pendingTasks.length,
                  itemBuilder: (context, index) {
                    final t = pendingTasks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t["id"]!, style: const TextStyle(color: kAccentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: t["risk"] == "Critique" ? Colors.red.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text("Risque: ${t["risk"]}", style: TextStyle(color: t["risk"] == "Critique" ? Colors.red : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(t["task"]!, style: const TextStyle(color: kTextMain, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text("Demandeur : ${t["requester"]}", style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), foregroundColor: Colors.red, minimumSize: const Size(80, 30)),
                                onPressed: () {
                                  setModalState(() => pendingTasks.removeAt(index));
                                  _showCustomSnackBar(parentContext, "Tâche ${t["id"]} rejetée.", Colors.red);
                                },
                                child: const Text("Rejeter", style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, minimumSize: const Size(90, 30)),
                                onPressed: () {
                                  setModalState(() => pendingTasks.removeAt(index));
                                  _showCustomSnackBar(parentContext, "Tâche ${t["id"]} autorisée et exécutée avec succès.", Colors.green);
                                },
                                child: const Text("Autoriser", style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProfileModal(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: kCardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(sheetContext).size.height * 0.65,
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
                IconButton(icon: const Icon(Icons.close, color: kTextSecondary), onPressed: () => Navigator.pop(sheetContext)),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10),
            _buildProfileInfoRow("Nom Complet", "Éloilid Mourdjain"),
            _buildProfileInfoRow("Statut", "Étudiant - Licence Pro Programmation & Réseaux"),
            _buildProfileInfoRow("Rôle Système", "Root / Administrateur Principal Sécurité"),
            _buildProfileInfoRow("Contacts", "+261 38 75 128 40 / +261 37 59 104 86"),
            _buildProfileInfoRow("Environnement", "Windows / Kali Linux / Docker / Flutter"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _showCustomSnackBar(parentContext, "Session verrouillée avec succès.", Colors.red);
                },
                child: const Text("Verrouiller la session admin"),
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

  // --- CONSOLE AVANCÉE DE SÉCURITÉ 2FA / MFA ULTRA CRYPTÉE ---
  void _openAdvanced2faModal(BuildContext parentContext) {
    bool isMfaEnforced = true;
    bool isAntiFatigueActive = true;
    bool isContextAwareActive = true;
    bool isPasskeysEnabled = true;
    bool isSsoIntegrated = true;

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: kCardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(sheetContext).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security, color: kAccentColor, size: 22),
                      SizedBox(width: 10),
                      Text("Console Centralisée 2FA / MFA & Conformité", style: TextStyle(color: kTextMain, fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, color: kTextSecondary), onPressed: () => Navigator.pop(sheetContext)),
                ],
              ),
              const Divider(color: Colors.white12),
              const SizedBox(height: 4),
              const Text("Renforcement ultime, chiffrement AES-256/TOTP et politiques strictes (RGPD, ISO 27001, NIS 2).", style: TextStyle(color: kTextSecondary, fontSize: 11)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    SwitchListTile(
                      title: const Text("Enrôlement obligatoire global (MFA)", style: TextStyle(color: kTextMain, fontSize: 13)),
                      subtitle: const Text("Bloque automatiquement les comptes salariés non configurés", style: TextStyle(color: kTextSecondary, fontSize: 11)),
                      value: isMfaEnforced,
                      activeThumbColor: kAccentColor,
                      onChanged: (val) {
                        setModalState(() => isMfaEnforced = val);
                        _showCustomSnackBar(parentContext, val ? "Enrôlement obligatoire activé" : "Enrôlement assoupli", val ? Colors.green : Colors.orange);
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Protection anti-lassitude (MFA Fatigue Antidote)", style: TextStyle(color: kTextMain, fontSize: 13)),
                      subtitle: const Text("Exige la correspondance de nombres (ex: saisir le chiffre 42 affiché)", style: TextStyle(color: kTextSecondary, fontSize: 11)),
                      value: isAntiFatigueActive,
                      activeThumbColor: kAccentColor,
                      onChanged: (val) {
                        setModalState(() => isAntiFatigueActive = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Détection de contexte (Context-Awareness)", style: TextStyle(color: kTextMain, fontSize: 13)),
                      subtitle: const Text("Blocage géographique strict (ex: refus si connexion hors pays autorisé / VPN)", style: TextStyle(color: kTextSecondary, fontSize: 11)),
                      value: isContextAwareActive,
                      activeThumbColor: kAccentColor,
                      onChanged: (val) {
                        setModalState(() => isContextAwareActive = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Passkeys / Clés d'accès sans mot de passe", style: TextStyle(color: kTextMain, fontSize: 13)),
                      subtitle: const Text("Authentification biométrique insensible au phishing (FaceID / Empreinte)", style: TextStyle(color: kTextSecondary, fontSize: 11)),
                      value: isPasskeysEnabled,
                      activeThumbColor: kAccentColor,
                      onChanged: (val) {
                        setModalState(() => isPasskeysEnabled = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Single Sign-On (SSO) d'entreprise", style: TextStyle(color: kTextMain, fontSize: 13)),
                      subtitle: const Text("Portail unique sécurisé pour Slack, Salesforce, Office 365...", style: TextStyle(color: kTextSecondary, fontSize: 11)),
                      value: isSsoIntegrated,
                      activeThumbColor: kAccentColor,
                      onChanged: (val) {
                        setModalState(() => isSsoIntegrated = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(8)),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Fonctionnalités & Protocoles Intégrés :", style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(height: 6),
                          Text("• Génération TOTP (codes éphémères toutes les 30 sec)\n• Notifications Push avec validation contextuelle en un clic\n• Codes de secours (Backup Codes) uniques hors ligne\n• Synchronisation & Restauration Cloud chiffrée multi-appareils\n• Traçabilité complète des logs (RGPD, ISO 27001, NIS 2)", style: TextStyle(color: kTextSecondary, fontSize: 11, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, minimumSize: const Size(double.infinity, 45)),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _showCustomSnackBar(parentContext, "Politiques de sécurité strictes déployées sur tous les terminaux.", Colors.green);
                },
                child: const Text("Appliquer les politiques de sécurité", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLogsModal(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: kCardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(sheetContext).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.text_snippet, color: Colors.orange, size: 22),
                    SizedBox(width: 10),
                    Text("Journaux de Connexion & Audit (IMMRED)", style: TextStyle(color: kTextMain, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: kTextSecondary), onPressed: () => Navigator.pop(sheetContext)),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10),
            const Text("Traçabilité complète (Heure, lieu, appareil et facteur de sécurité validé) :", style: TextStyle(color: kTextSecondary, fontSize: 12)),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(8)),
                child: ListView(
                  children: const [
                    Text("[AUTH] 2026-07-30 23:10:12 - User: Eloilid Mourdjain | IP: 192.168.1.10 (FR) | Passkeys OK", style: TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'monospace')),
                    SizedBox(height: 6),
                    Text("[MFA]  2026-07-30 22:45:33 - Anti-fatigue match validated (Code 42) | Device trusted", style: TextStyle(color: kAccentColor, fontSize: 11, fontFamily: 'monospace')),
                    SizedBox(height: 6),
                    Text("[WARN] 2026-07-30 21:15:40 - Blocked foreign auth attempt from ASIA (Context-Awareness)", style: TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'monospace')),
                    SizedBox(height: 6),
                    Text("[AUDIT]2026-07-30 20:00:00 - ISO 27001 compliance snapshot generated successfully.", style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    onPressed: () {
                      _showCustomSnackBar(parentContext, "Rapport d'audit enregistré localement.", Colors.teal);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text("Enregistrer"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    onPressed: () {
                      _showCustomSnackBar(parentContext, "Extraction des journaux de conformité en cours...", Colors.orange);
                    },
                    icon: const Icon(Icons.file_download, size: 16),
                    label: const Text("Extraire (.tar.gz)"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
                const Text("Éloilid Mourdjain", style: TextStyle(color: kTextMain, fontWeight: FontWeight.bold)),
                Text("Admin - DarckCyber", style: TextStyle(color: kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          ListTile(title: const Text("Tableau de bord", style: TextStyle(color: kTextMain)), leading: const Icon(Icons.dashboard, color: kAccentColor), onTap: () => Navigator.pop(context)),
          ListTile(
            title: const Text("Profil Complet", style: TextStyle(color: kTextMain)),
            leading: const Icon(Icons.person, color: Colors.teal),
            onTap: () {
              Navigator.pop(context);
              _openProfileModal(context);
            },
          ),
          ListTile(
            title: const Text("Gestion Avancée de Sécurité & 2FA", style: TextStyle(color: kTextMain)),
            leading: const Icon(Icons.security, color: kPrimaryColor),
            onTap: () {
              Navigator.pop(context);
              _openAdvanced2faModal(context);
            },
          ),
          ListTile(
            title: const Text("Autorisation de Tâches", style: TextStyle(color: kTextMain)),
            leading: const Icon(Icons.rule, color: Colors.teal),
            onTap: () {
              Navigator.pop(context);
              _openTaskAuthorizationModal(context);
            },
          ),
          ListTile(
            title: const Text("Journaux & Audit de Conformité", style: TextStyle(color: kTextMain)),
            leading: const Icon(Icons.text_snippet, color: Colors.orange),
            onTap: () {
              Navigator.pop(context);
              _openLogsModal(context);
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
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
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
        splashColor: color.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBarDetail("Enrôlement MFA Salariés", 148, 150, Colors.green),
          const SizedBox(height: 12),
          _buildProgressBarDetail("Conformité ISO 27001 / NIS2", 95, 100, Colors.purple),
          const SizedBox(height: 12),
          _buildProgressBarDetail("Requêtes Context-Awareness filtrées", 412, 412, kAccentColor),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 14),
              SizedBox(width: 6),
              Expanded(
                child: Text("Aucune violation de conformité détectée ce mois-ci.",
                  style: TextStyle(color: kTextSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
      ..color = kAccentColor.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const double gridSize = 45.0;
    double offset = animationValue * gridSize;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = offset; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CyberGridPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}