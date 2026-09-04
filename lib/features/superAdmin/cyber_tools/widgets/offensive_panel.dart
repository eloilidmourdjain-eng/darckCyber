import 'package:flutter/material.dart';

class OffensiveActionPage extends StatelessWidget {
  const OffensiveActionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F172A),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Panneau d'actions Red Team (Pentest)",
            style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Text(
                "Outils de simulation d'attaque prêts à l'exécution.",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
