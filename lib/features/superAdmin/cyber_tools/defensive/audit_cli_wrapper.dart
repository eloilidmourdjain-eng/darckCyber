class AuditCliWrapper {
  // Regex stricte pour valider une IPv4, une IPv6 ou un sous-réseau CIDR (ex: 192.168.1.0/24)
  static final RegExp _safeTargetRegex = RegExp(r'^(((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}(\/(1[6-9]|2[0-9]|3[0-2]))?)|localhost$');

  /// Construit la liste d'arguments de manière sécurisée selon le profil choisi
  static Map<String, dynamic> buildCommand({
    required String toolName,
    required String target,
    required String auditProfile,
  }) {
    List<String> arguments = [];
    String executable = '';

    String cleanTarget = target.trim().toLowerCase();

    // 1. VÉRIFICATION DE SÉCURITÉ (Validation des entrées)
    if (!_safeTargetRegex.hasMatch(cleanTarget)) {
      throw ArgumentError("[BLOCAGE SÉCURITÉ] La cible '$target' n'est pas une IP, un CIDR ou un 'localhost' valide.");
    }

    // 2. SÉLECTION DES OUTILS ET PROFILS
    switch (toolName.toLowerCase()) {

    // --- NMAP : DÉCOUVERTE ET AUDIT DES PORTS ---
      case 'nmap':
        executable = 'nmap';
        if (auditProfile == 'fast_discovery') {
          // Découverte rapide (Ping Sweep) sans scan de ports profonds
          arguments = ['-sn', '-T4', cleanTarget];
        } else if (auditProfile == 'service_audit') {
          // Identification des versions de services sur les 100 ports les plus courants
          arguments = ['-sV', '-T3', '--top-ports', '100', cleanTarget];
        } else {
          // Fallback : Scan rapide par défaut
          arguments = ['-F', cleanTarget];
        }
        break;

    // --- TSHARK : WIRESHARK EN LIGNE DE COMMANDE ---
      case 'tshark':
        executable = 'tshark';
        if (auditProfile == 'capture_dns') {
          // Sniffe le port 53 (DNS) et s'arrête après 50 paquets
          arguments = ['-i', 'any', '-f', 'udp port 53', '-c', '50'];
        } else if (auditProfile == 'capture_tcp') {
          // Capture le trafic TCP lié à la cible et s'arrête après 100 paquets
          arguments = ['-i', 'any', '-Y', 'ip.addr == $cleanTarget and tcp', '-c', '100'];
        } else {
          // Capture brute (limitée à 20 paquets pour éviter un crash OOM)
          arguments = ['-i', 'any', 'host', cleanTarget, '-c', '20'];
        }
        break;

    // --- IPERF3 : DIAGNOSTIC DE BANDE PASSANTE ---
      case 'iperf3':
        executable = 'iperf3';
        if (auditProfile == 'bandwidth_test') {
          // Lance un test client vers le serveur iPerf cible pendant 10 secondes
          arguments = ['-c', cleanTarget, '-t', '10'];
        }
        break;

    // --- MTR : DIAGNOSTIC DE ROUTAGE DYNAMIQUE ---
      case 'mtr':
        executable = 'mtr';
        if (auditProfile == 'diag_route') {
          // Traceroute dynamique avec génération d'un rapport textuel après 5 cycles
          arguments = ['--report', '--report-cycles', '5', cleanTarget];
        }
        break;

      default:
        throw ArgumentError("Outil de diagnostic réseau non pris en charge : $toolName");
    }

    // Retourne les données formatées pour le ProcessManager
    return {
      'executable': executable,
      'arguments': arguments,
    };
  }
}