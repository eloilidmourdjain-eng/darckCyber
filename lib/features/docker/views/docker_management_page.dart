import 'package:flutter/material.dart';
import '../models/container_model.dart';
import '../services/ssh_docker_service.dart';

class DockerManagementPage extends StatefulWidget {
  const DockerManagementPage({super.key});

  @override
  State<DockerManagementPage> createState() => _DockerManagementPageState();
}

class _DockerManagementPageState extends State<DockerManagementPage> {
  final SshDockerService _sshDockerService = SshDockerService();

  bool _isConnected = false;
  bool _isLoading = false;
  List<ContainerModel> _containers = [];
  String _statusLog = "Prêt à se connecter au démon Docker distant.";

  // Contrôleurs pour les champs de connexion SSH
  final TextEditingController _hostController = TextEditingController(text: "192.168.1.100");
  final TextEditingController _portController = TextEditingController(text: "22");
  final TextEditingController _userController = TextEditingController(text: "admin");
  final TextEditingController _passwordController = TextEditingController(text: "");

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _sshDockerService.disconnect();
    super.dispose();
  }

  // Connexion au serveur distant et récupération des conteneurs
  Future<void> _connectAndFetch() async {
    setState(() {
      _isLoading = true;
      _statusLog = "Connexion SSH en cours vers ${_hostController.text}[cite: 7, 8]...";
    });

    final success = await _sshDockerService.connect(
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 22,
      username: _userController.text.trim(),
      password: _passwordController.text,
    );

    if (success) {
      setState(() {
        _isConnected = true;
        _statusLog = "Connecté avec succès. Récupération des conteneurs...";
      });
      await _loadContainers();
    } else {
      setState(() {
        _isLoading = false;
        _statusLog = "Échec de la connexion SSH (Vérifiez les identifiants)[cite: 7, 8].";
      });
    }
  }

  // Charger ou rafraîchir la liste des conteneurs
  Future<void> _loadContainers() async {
    try {
      final containers = await _sshDockerService.getContainers();
      setState(() {
        _containers = containers;
        _isLoading = false;
        _statusLog = "Inventaire Docker mis à jour (${containers.length} conteneurs).";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusLog = "Erreur : $e";
      });
    }
  }

  // Basculer l'état (Démarrer / Arrêter) d'un conteneur
  Future<void> _toggleContainer(ContainerModel container) async {
    setState(() => _isLoading = true);
    try {
      if (container.isRunning) {
        await _sshDockerService.stopContainer(container.id);
      } else {
        await _sshDockerService.startContainer(container.id);
      }
      await _loadContainers();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusLog = "Erreur d'action : $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("DockPulse - Gestion Docker", style: TextStyle(color: Colors.white, fontSize: 15)),
        iconTheme: const IconThemeData(color: Color(0xFF38BDF8)),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8)),
              onPressed: _isLoading ? null : _loadContainers,
              tooltip: "Rafraîchir",
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Connexion / Statut
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PARAMÈTRES DE CONNEXION SSH", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (!_isConnected) ...[
                    Row(
                      children: [
                        Expanded(flex: 3, child: TextField(controller: _hostController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: "Hôte / IP", labelStyle: TextStyle(color: Colors.grey)))) ,
                        const SizedBox(width: 8),
                        Expanded(flex: 1, child: TextField(controller: _portController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: "Port", labelStyle: TextStyle(color: Colors.grey)))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _userController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: "Utilisateur", labelStyle: TextStyle(color: Colors.grey)))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _passwordController, obscureText: true, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: "Mot de passe", labelStyle: TextStyle(color: Colors.grey)))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: const Color(0xFF0F172A)),
                        onPressed: _isLoading ? null : _connectAndFetch,
                        child: Text(_isLoading ? "Connexion..." : "Établir la liaison SSH"),
                      ),
                    ),
                  ] else ...[
                    Text(_statusLog, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace')),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      onPressed: () {
                        _sshDockerService.disconnect();
                        setState(() {
                          _isConnected = false;
                          _containers = [];
                          _statusLog = "Déconnecté.";
                        });
                      },
                      icon: const Icon(Icons.logout, size: 14),
                      label: const Text("Fermer la session SSH", style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text("CONTENEURS ACTIFS ET DISTANTS", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Liste des conteneurs
            Expanded(
              child: _isLoading && _containers.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                  : _containers.isEmpty
                  ? const Center(child: Text("Aucun conteneur à afficher. Connectez-vous.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)))
                  : ListView.builder(
                itemCount: _containers.length,
                itemBuilder: (context, index) {
                  final container = _containers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: container.isRunning ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.layers, color: container.isRunning ? Colors.greenAccent : Colors.redAccent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(container.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text("Image: ${container.image} • ID: ${container.id.substring(0, 8)}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'monospace')),
                              const SizedBox(height: 4),
                              Text(container.status, style: TextStyle(color: container.isRunning ? Colors.green : Colors.red, fontSize: 10)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(container.isRunning ? Icons.stop : Icons.play_arrow, color: container.isRunning ? Colors.redAccent : Colors.greenAccent),
                          onPressed: _isLoading ? null : () => _toggleContainer(container),
                          tooltip: container.isRunning ? "Arrêter" : "Démarrer",
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
    );
  }
}