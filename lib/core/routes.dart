import 'package:flutter/material.dart';

// Imports des modules (les erreurs actuelles disparaîtront quand on les remplira)
import 'package:darck_puls/features/security/security_alerts_screen.dart';
import 'package:darck_puls/features/network_analysis/wifi_analyzer_screen.dart';
import 'package:darck_puls/features/topology/ai_topology_screen.dart';
import 'package:darck_puls/features/traffic_management/traffic_management_screen.dart';
import 'package:darck_puls/features/provisioning/architecture_provisioning_screen.dart';
import 'package:darck_puls/features/maintenance/maintenance_screen.dart';

// TODO: Assure-toi que le chemin correspond à ton fichier dashboard existant
// import '../features/dashboard/dashboard.dart';

class AppRoutes {
  // Définition des constantes pour éviter les fautes de frappe lors des appels
  static const String dashboard = '/';
  static const String security = '/security';
  static const String network = '/network';
  static const String topology = '/topology';
  static const String traffic = '/traffic';
  static const String provisioning = '/provisioning';
  static const String maintenance = '/maintenance';

  // Dictionnaire des routes injecté dans le MaterialApp
  static Map<String, WidgetBuilder> define() {
    return {
      // dashboard: (context) => const Dashboard(), // Décommente et utilise le nom de ta classe Dashboard
      security: (context) => const SecurityAlertsScreen(),
      network: (context) => const WifiAnalyzerScreen(),
      topology: (context) => const AITopologyScreen(),
      traffic: (context) => const TrafficManagementScreen(),
      provisioning: (context) => const ArchitectureAndProvisioningScreen(),
      maintenance: (context) => const MaintenanceScreen(),
    };
  }
}