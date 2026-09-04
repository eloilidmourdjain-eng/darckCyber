import 'package:flutter/material.dart';
import 'package:darck_puls/core/models/user_role.dart';

class DashboardPage extends StatelessWidget {
  final UserRole userRole;

  const DashboardPage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tableau de bord - ${userRole.name}"),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Text(
          "Bienvenue dans l'espace sécurisé (${userRole.name})",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
