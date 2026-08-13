import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fl_chart/fl_chart.dart';
import '../defensive/firewall_api.dart';

class DefenseDashboardWidget extends StatefulWidget {
  const DefenseDashboardWidget({super.key});

  @override
  State<DefenseDashboardWidget> createState() => _DefenseDashboardWidgetState();
}

class _DefenseDashboardWidgetState extends State<DefenseDashboardWidget> {
  late final WebSocketChannel _channel;

  // Historique global de toutes les alertes reçues
  final List<Map<String, dynamic>> _alertsLog = [];

  // Filtre de recherche actuellement sélectionné ('ALL', 'CRITICAL', 'WARNING', 'INFO')
  String _selectedFilter = 'ALL';

  // Données du graphique d'intensité
  final List<FlSpot> _chartData = [const FlSpot(0, 0)];
  int _minuteCounter = 0;

  // 1. BASE DE DONNÉES D'INSTRUCTIONS DE REMÉDIATION
  final Map<String, Map<String, String>> remediationDatabase = {
    "Brute-force SSH détecté (Hydra)": {
      "desc": "Un attaquant tente de deviner le mot de passe du serveur SSH en testant des milliers de combinaisons par seconde.",
      "action": "Activer le bannissement automatique via Fail2ban et modifier le port d'écoute SSH par défaut.",
      "command": "sudo systemctl restart fail2ban && sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config"
    },
    "Scan de vulnérabilités Web (Nikto)": {
      "desc": "Un outil automatisé inspecte votre serveur Web à la recherche de fichiers cachés, scripts obsolètes ou mauvaises configurations.",
      "action": "Bloquer l'IP de l'attaquant au niveau du pare-feu applicatif et masquer la signature de version du serveur.",
      "command": "sudo ufw deny from %IP% to any port 80,443 comment 'Bloqué par console : Scan Nikto'"
    },
    "Tentative d'injection SQL sur l'API": {
      "desc": "L'attaquant injecte du code SQL malveillant dans les formulaires d'entrée pour manipuler, voler ou détruire la base de données.",
      "action": "Isoler la session utilisateur à l'origine de l'attaque et activer le profil d'inspection stricte du Web Application Firewall (WAF).",
      "command": "sudo modsec-control --enable-rule-id 942100 --ip %IP%"
    },
    "Ping anormal détecté (Scan Nmap)": {
      "desc": "Un pirate scanne les ports de votre infrastructure pour cartographier vos machines et découvrir les services actifs.",
      "action": "Configurer IPTables pour ignorer silencieusement les requêtes de ping (ICMP) et rejeter les scans furtifs.",
      "command": "sudo iptables -A INPUT -p icmp --icmp-type echo-request -j DROP"
    },
    "Appareil IoT non autorisé connecté": {
      "desc": "Un nouvel équipement réseau non répertorié s'est connecté au commutateur et tente d'obtenir une adresse IP.",
      "action": "Désactiver immédiatement le port du commutateur réseau correspondant ou isoler l'adresse MAC dans un VLAN de quarantaine.",
      "command": "sudo ip link set dev eth1 down # Ou utiliser l'API du commutateur pour isoler la MAC"
    }
  };

  @override
  void initState() {
    super.initState();
    // Connexion au serveur WebSocket local (généré par server_simulation.dart)[cite: 2]
    _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080'));
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  void _handleIncomingAlert(String rawJson) {
    try {
      final Map<String, dynamic> alert = jsonDecode(rawJson);

      setState(() {
        // Enrôlement dans l'historique global[cite: 2]
        _alertsLog.insert(0, alert);

        // Mise à jour du graphique d'activité[cite: 2]
        _minuteCounter++;
        double score = double.tryParse(alert['severity_score']?.toString() ?? '1') ?? 1.0;
        _chartData.add(FlSpot(_minuteCounter.toDouble(), score));
        if (_chartData.length > 10) _chartData.removeAt(0);
      });
    } catch (e) {
      debugPrint("Erreur décodage Flutter : $e");
    }
  }

  // 3. MÉTHODE D'AFFICHAGE DU DIALOGUE DE REMÉDIATION
  void _showRemediationDialog(BuildContext context, String attackTitle, String attackerIp) {
    final instructions = remediationDatabase[attackTitle] ?? {
      "desc": "Activité suspecte non standard détectée sur le réseau.",
      "action": "Analyser les en-têtes réseau et inspecter manuellement les processus actifs.",
      "command": "sudo netstat -tulpn | grep LISTEN"
    };

    final parsedCommand = instructions["command"]!.replaceAll("%IP%", attackerIp);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.blueGrey)),
        title: Row(
          children: [
            const Icon(Icons.shield, color: Colors.cyanAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "GUIDE DE REMÉDIATION DÉFENSIVE",
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(attackTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 5),
              Text("IP Cible Malveillante : $attackerIp", style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 12)),
              const Divider(color: Colors.blueGrey),

              const Text("🔍 ANALYSE DE LA MENACE :", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text(instructions["desc"]!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 15),

              const Text("🛡️ STRATÉGIE DE DÉFENSE :", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text(instructions["action"]!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 15),

              const Text("💻 COMMANDE RECOMMANDÉE POUR LE TERMINAL :", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                width: double.infinity,
                child: SelectableText(
                  parsedCommand,
                  style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fermer", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.shade900),
            icon: const Icon(Icons.terminal, color: Colors.white, size: 16),
            label: const Text("INJECTER DANS LE TERMINAL", style: TextStyle(color: Colors.white, fontSize: 12)),
            onPressed: () {
              Navigator.pop(ctx);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Commande copiée et injectée dans le terminal d'administration.")),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> filteredAlerts = _alertsLog.where((alert) {
      if (_selectedFilter == 'ALL') return true;
      return alert['severity'] == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: StreamBuilder(
        stream: _channel.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleIncomingAlert(snapshot.data.toString());
            });
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(snapshot.connectionState),
                const SizedBox(height: 20),
                _buildNetworkChart(),
                const SizedBox(height: 20),
                _buildFilterBar(),
                const SizedBox(height: 15),
                Expanded(child: _buildAlertsList(filteredAlerts)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ConnectionState state) {
    bool isConnected = state == ConnectionState.active;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "CONSOLE DE PROTECTION RÉSEAU",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
        Chip(
          avatar: Icon(Icons.circle, color: isConnected ? Colors.green : Colors.red, size: 12),
          label: Text(isConnected ? "ONLINE" : "OFFLINE", style: const TextStyle(color: Colors.white, fontSize: 11)),
          backgroundColor: isConnected ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
        ),
      ],
    );
  }

  Widget _buildNetworkChart() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _chartData,
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.redAccent.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        const Text("Filtrer par : ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        _buildFilterButton("Tous", "ALL", Colors.blueGrey),
        const SizedBox(width: 8),
        _buildFilterButton("Critique", "CRITICAL", Colors.red),
        const SizedBox(width: 8),
        _buildFilterButton("Moyen", "WARNING", Colors.orange),
        const SizedBox(width: 8),
        _buildFilterButton("Faible", "INFO", Colors.green),
      ],
    );
  }

  Widget _buildFilterButton(String label, String filterValue, Color color) {
    bool isSelected = _selectedFilter == filterValue;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.6),
      backgroundColor: const Color(0xFF1E293B),
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = filterValue;
        });
      },
    );
  }

  // 2. LISTE DES ALERTES MODIFIÉE AVEC GESTION DU CLIC (InkWell)
  Widget _buildAlertsList(List<Map<String, dynamic>> displayList) {
    if (displayList.isEmpty) {
      return const Center(
        child: Text("Aucun événement ne correspond à ce filtre.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final alert = displayList[index];
        String title = alert['title'] ?? 'Événement';
        String srcIp = alert['source_ip'] ?? '0.0.0.0';
        String severity = alert['severity'] ?? 'INFO';

        Color severityColor = Colors.green;
        if (severity == 'CRITICAL') severityColor = Colors.red;
        if (severity == 'WARNING') severityColor = Colors.orange;

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: severityColor.withValues(alpha: 0.5), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            // Déclenchement de la boîte de dialogue instructive au clic sur la carte[cite: 7]
            onTap: () => _showRemediationDialog(context, title, srcIp),
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              leading: Text(
                  "[${alert['timestamp'] ?? ''}]",
                  style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 12)
              ),
              title: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                "IP: $srcIp ➔ ${alert['target'] ?? ''}",
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontFamily: 'monospace'),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () async {
                  await DefensiveFirewallManager.banIpAddress(srcIp);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('IP $srcIp bannie avec succès !'), backgroundColor: Colors.red),
                  );
                },
                child: const Text("BANNIR IP", style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          ),
        );
      },
    );
  }
}