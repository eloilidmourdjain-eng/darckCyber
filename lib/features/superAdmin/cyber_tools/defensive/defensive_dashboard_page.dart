import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DefensiveDashboardPage extends StatefulWidget {
  const DefensiveDashboardPage({super.key});

  @override
  State<DefensiveDashboardPage> createState() => _DefensiveDashboardPageState();
}

class _DefensiveDashboardPageState extends State<DefensiveDashboardPage> {
  // Coordonnées pour le graphique d'intensité des attaques (Temps vs Gravité)
  final List<FlSpot> _attackPoints = [
    const FlSpot(0, 1),
    const FlSpot(1, 3),
    const FlSpot(2, 2),
    const FlSpot(3, 5),
    const FlSpot(4, 4),
    const FlSpot(5, 8),
  ];

  // Filtre actif pour les alertes de sécurité ('ALL', 'CRITICAL', 'WARNING', 'INFO')
  String _selectedFilter = 'ALL';

  // Liste initiale des alertes de sécurité en mémoire
  final List<Map<String, dynamic>> _alerts = [
    {
      "id": "1",
      "type": "Brute-force SSH",
      "ip": "192.168.1.150",
      "severity": "CRITICAL",
      "time": "12:40"
    },
    {
      "id": "2",
      "type": "Port Scan Nmap",
      "ip": "10.0.0.45",
      "severity": "WARNING",
      "time": "12:42"
    },
    {
      "id": "3",
      "type": "Requête HTTP Suspecte",
      "ip": "172.16.0.8",
      "severity": "INFO",
      "time": "12:45"
    },
  ];

  // Boîte de dialogue de remédiation au clic sur une alerte
  void _showRemediationDialog(Map<String, dynamic> alert) {
    String attackerIp = alert["ip"];
    String remediationCommand = "sudo ufw deny from $attackerIp";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          "Remédiation : ${alert["type"]}",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "IP Ciblée : $attackerIp",
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Stratégie de défense recommandée : Bannissement immédiat via pare-feu système.",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                remediationCommand,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Commande injectée : $remediationCommand"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            icon: const Icon(Icons.block, size: 14, color: Colors.white),
            label: const Text(
              "Bannir l'IP",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtrage dynamique des alertes selon le niveau de gravité sélectionné
    final filteredAlerts = _alerts.where((alert) {
      if (_selectedFilter == 'ALL') return true;
      return alert["severity"] == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "Dashboard Défensif",
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF38BDF8)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "GRAPHIQUE D'INTENSITÉ DES ATTAQUES",
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _attackPoints,
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.redAccent.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "FLUX D'ALERTES SÉCURITÉ",
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _selectedFilter,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text("Tous")),
                  DropdownMenuItem(value: 'CRITICAL', child: Text("Critique")),
                  DropdownMenuItem(
                    value: 'WARNING',
                    child: Text("Avertissement"),
                  ),
                  DropdownMenuItem(value: 'INFO', child: Text("Info")),
                ],
                onChanged: (val) => setState(() => _selectedFilter = val!),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...filteredAlerts.map(
                (alert) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: alert["severity"] == 'CRITICAL'
                      ? Colors.red.withValues(alpha: 0.4)
                      : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    alert["severity"] == 'CRITICAL'
                        ? Icons.warning
                        : Icons.info,
                    color: alert["severity"] == 'CRITICAL'
                        ? Colors.redAccent
                        : Colors.orangeAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert["type"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Attaquant : ${alert['ip']} • ${alert['time']}",
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: () => _showRemediationDialog(alert),
                    child: const Text(
                      "Remédier",
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}