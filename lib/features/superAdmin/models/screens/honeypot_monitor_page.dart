import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:darck_puls/features/superAdmin/models/honeypot_alert.dart';

class HoneypotMonitorWidget extends StatefulWidget {
  final String apiBaseUrl; // ex: 'http://localhost:8080'

  const HoneypotMonitorWidget({super.key, required this.apiBaseUrl});

  @override
  State<HoneypotMonitorWidget> createState() => _HoneypotMonitorWidgetState();
}

class _HoneypotMonitorWidgetState extends State<HoneypotMonitorWidget> {
  List<HoneypotAlert> alerts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/api/honeypot/alerts'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          alerts = data.map((json) => HoneypotAlert.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _blockAttacker(String ip, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/honeypot/block'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ip_address': ip, 'user_id': userId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action réussie : IP $ip isolée du réseau[cite: 12].'), backgroundColor: Colors.red),
        );
        _fetchAlerts();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de communication : $e'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.gpp_bad, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'CENTRE DE SURVEILLANCE DES POTS DE MIEL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                onPressed: _fetchAlerts,
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : alerts.isEmpty
              ? const Text(
            'Aucune intrusion détectée pour le moment. Système sécurisé.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Card(
                color: Colors.red.shade900.withOpacity(0.2),
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.red.shade300, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ALERTE : ${alert.triggerType}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent),
                      ),
                      const SizedBox(height: 6),
                      Text('📍 Adresse IP : ${alert.ipAddress}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Text('🖥️ Appareil : ${alert.deviceFingerprint}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      Text('🕒 Heure : ${alert.timestamp}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _fetchAlerts,
                            child: const Text('Ignorer', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _blockAttacker(alert.ipAddress, alert.userId),
                            child: const Text('BANNIR L\'IP & COUPER LES ACCÈS', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}