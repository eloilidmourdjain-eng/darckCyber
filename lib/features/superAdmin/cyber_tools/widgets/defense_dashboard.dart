import 'package:flutter/material.dart';
import 'package:darck_puls/features/superAdmin/screens/honeypot_monitor_page.dart'; // Ajustez si nécessaire

class DefenseDashboardWidget extends StatelessWidget {
  const DefenseDashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F172A),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tableau de bord de Défense SOC & SIEM",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Text(
                "Flux SIEM et métriques de sécurité actifs.",
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
