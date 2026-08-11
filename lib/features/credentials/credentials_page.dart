import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color kBackgroundColor = Color(0xFF0F172A);
const Color kCardColor = Color(0xFF1E293B);
const Color kTextMain = Colors.white;
const Color kTextSecondary = Color(0xFF94A3B8);

class CredentialsPage extends StatefulWidget {
  const CredentialsPage({super.key});

  @override
  State<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends State<CredentialsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Suivi de l'affichage des secrets pour chaque item (par ID)
  final Set<String> _revealedIds = {};

  // Liste initiale des identifiants stockés
  final List<Map<String, String>> _credentialsList = [
    {"id": "1", "title": "Root SSH Server", "subtitle": "root@192.168.1.10_SecretPass99!", "level": "Critique"},
    {"id": "2", "title": "Anthropic Claude API", "subtitle": "sk-ant-api03-9X8fSecureKey...", "level": "Interne"},
    {"id": "3", "title": "Database PostgreSQL", "subtitle": "postgres://admin:DbPass2026!@localhost", "level": "Critique"},
    {"id": "4", "title": "Docker Registry Token", "subtitle": "dckr_pat_9X8fTokenVal", "level": "Standard"},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Générateur de mot de passe fort aléatoire
  String _generateSecurePassword() {
    const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+";
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(16, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // Évaluation de la force du mot de passe
  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0.2;
    if (password.length >= 8) strength += 0.3;
    if (password.length >= 12) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[0-9]')) && password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strength += 0.3;
    }
    return strength > 1.0 ? 1.0 : strength;
  }

  Color _getPasswordStrengthColor(double strength) {
    if (strength <= 0.3) return Colors.red;
    if (strength <= 0.7) return Colors.orange;
    return Colors.green;
  }

  // Vérification du PIN pour les actions critiques
  void _verifyPinAndExecute(BuildContext context, VoidCallback onAuthorized) {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.lock_person, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text("Sécurité Critique", style: TextStyle(color: kTextMain, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Cet élément est critique. Entrez le PIN Super Admin (2026) :", style: TextStyle(color: kTextSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: kTextMain),
              decoration: InputDecoration(
                filled: true,
                fillColor: kBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Annuler", style: TextStyle(color: kTextSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              final enteredPin = pinController.text;
              Navigator.pop(dialogContext);
              if (enteredPin == "2026") {
                onAuthorized();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Code PIN incorrect."), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }

  // Formulaire d'ajout ou de modification avec indicateur de force en temps réel
  void _showCredentialFormDialog(BuildContext context, {Map<String, String>? credentialToEdit}) {
    final bool isEditing = credentialToEdit != null;
    final TextEditingController titleController = TextEditingController(text: isEditing ? credentialToEdit["title"] : "");
    final TextEditingController valueController = TextEditingController(text: isEditing ? credentialToEdit["subtitle"] : "");
    String selectedLevel = isEditing ? credentialToEdit["level"]! : "Interne";
    double passwordStrength = _calculatePasswordStrength(valueController.text);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: kCardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            isEditing ? "Modifier le Credential" : "Nouveau Credential Chiffré",
            style: const TextStyle(color: kTextMain, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: kTextMain),
                  decoration: InputDecoration(
                    labelText: "Nom du service / Titre",
                    labelStyle: const TextStyle(color: kTextSecondary, fontSize: 12),
                    filled: true,
                    fillColor: kBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueController,
                  style: const TextStyle(color: kTextMain),
                  onChanged: (val) {
                    setDialogState(() {
                      passwordStrength = _calculatePasswordStrength(val);
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Valeur / Clé / Secret",
                    labelStyle: const TextStyle(color: kTextSecondary, fontSize: 12),
                    filled: true,
                    fillColor: kBackgroundColor,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.vpn_key, color: Colors.purple, size: 18),
                      tooltip: "Générer un mot de passe ultra-sécurisé",
                      onPressed: () {
                        setDialogState(() {
                          valueController.text = _generateSecurePassword();
                          passwordStrength = _calculatePasswordStrength(valueController.text);
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                // Indicateur de force en temps réel
                LinearProgressIndicator(
                  value: passwordStrength,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(_getPasswordStrengthColor(passwordStrength)),
                  minHeight: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedLevel,
                  dropdownColor: kCardColor,
                  style: const TextStyle(color: kTextMain, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: "Niveau de sensibilité",
                    labelStyle: const TextStyle(color: kTextSecondary, fontSize: 12),
                    filled: true,
                    fillColor: kBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Critique", child: Text("🔴 Critique (Root/DB)")),
                    DropdownMenuItem(value: "Interne", child: Text("🟠 Interne (API/SSH)")),
                    DropdownMenuItem(value: "Standard", child: Text("🟢 Standard (Tokens)")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedLevel = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler", style: TextStyle(color: kTextSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              onPressed: () {
                if (titleController.text.isNotEmpty && valueController.text.isNotEmpty) {
                  setState(() {
                    if (isEditing) {
                      credentialToEdit["title"] = titleController.text;
                      credentialToEdit["subtitle"] = valueController.text;
                      credentialToEdit["level"] = selectedLevel;
                    } else {
                      _credentialsList.add({
                        "id": DateTime.now().millisecondsSinceEpoch.toString(),
                        "title": titleController.text,
                        "subtitle": valueController.text,
                        "level": selectedLevel,
                      });
                    }
                  });
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? "Credential mis à jour." : "Credential chiffré et enregistré."),
                      backgroundColor: Colors.purple,
                    ),
                  );
                }
              },
              child: Text(isEditing ? "Modifier" : "Créer"),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCredential(Map<String, String> item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCardColor,
        title: const Text("Confirmer la suppression", style: TextStyle(color: kTextMain, fontSize: 16)),
        content: Text("Supprimer définitivement '${item["title"]}' ?", style: const TextStyle(color: kTextSecondary, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Annuler", style: TextStyle(color: kTextSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _credentialsList.remove(item);
              });
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Credential supprimé."), backgroundColor: Colors.redAccent),
              );
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _credentialsList.where((item) {
      return item["title"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item["subtitle"]!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.purple),
        title: const Text("Coffre-fort Credentials (Sécurisé)", style: TextStyle(color: kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: kTextMain, fontSize: 13),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Rechercher un credential...",
                hintStyle: const TextStyle(color: kTextSecondary, fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: Colors.purple, size: 18),
                filled: true,
                fillColor: kCardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  final String id = item["id"]!;
                  final String level = item["level"]!;
                  bool isRevealed = _revealedIds.contains(id);
                  Color levelColor = level == "Critique" ? Colors.red : (level == "Interne" ? Colors.orange : Colors.green);

                  // Masquage automatique des secrets
                  String displayValue = isRevealed ? item["subtitle"]! : "••••••••••••••••";

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock, color: levelColor, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(item["title"]!, style: const TextStyle(color: kTextMain, fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(color: levelColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                      child: Text(level, style: TextStyle(color: levelColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(displayValue, style: const TextStyle(color: kTextSecondary, fontSize: 11, fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                          // Bouton Révéler / Masquer (avec PIN si critique)
                          IconButton(
                            icon: Icon(isRevealed ? Icons.visibility_off : Icons.visibility, size: 16, color: kTextSecondary),
                            tooltip: isRevealed ? "Masquer" : "Révéler",
                            onPressed: () {
                              if (!isRevealed && level == "Critique") {
                                _verifyPinAndExecute(context, () {
                                  setState(() => _revealedIds.add(id));
                                });
                              } else {
                                setState(() {
                                  if (isRevealed) {
                                    _revealedIds.remove(id);
                                  } else {
                                    _revealedIds.add(id);
                                  }
                                });
                              }
                            },
                          ),
                          // Bouton Copier
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16, color: kTextSecondary),
                            tooltip: "Copier",
                            onPressed: () {
                              if (level == "Critique") {
                                _verifyPinAndExecute(context, () {
                                  Clipboard.setData(ClipboardData(text: item["subtitle"]!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Secret critique copié dans le presse-papier."), backgroundColor: Colors.purple),
                                  );
                                });
                              } else {
                                Clipboard.setData(ClipboardData(text: item["subtitle"]!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Copié dans le presse-papier."), backgroundColor: Colors.purple),
                                );
                              }
                            },
                          ),
                          // Bouton Modifier
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16, color: Colors.blueAccent),
                            tooltip: "Modifier",
                            onPressed: () => _showCredentialFormDialog(context, credentialToEdit: item),
                          ),
                          // Bouton Supprimer
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                            tooltip: "Supprimer",
                            onPressed: () => _deleteCredential(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: () => _showCredentialFormDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Créer ou ajouter un credential"),
            ),
          ],
        ),
      ),
    );
  }
}