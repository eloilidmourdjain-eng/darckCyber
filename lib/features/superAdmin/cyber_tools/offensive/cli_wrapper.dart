class OffensiveCliWrapper {
  /// Convertit les options graphiques en une liste d'arguments pour un outil de pentesting (ex: Nmap, Nikto)[cite: 7]
  static Map<String, dynamic> buildCommand({
    required String toolName,
    required String target,
    String? options,
  }) {
    List<String> arguments = [];
    String executable = '';

    switch (toolName.toLowerCase()) {
      case 'nmap':
        executable = 'nmap';
        // Exemple : Scan de ports basique ou avancé selon les options
        arguments = [options ?? '-T4', '-F', target];
        break;

      case 'nikto':
        executable = 'nikto';
        // Exemple : Scan de vulnérabilités web[cite: 4]
        arguments = ['-h', target];
        if (options != null && options.isNotEmpty) {
          arguments.addAll(options.split(' '));
        }
        break;

      case 'hydra':
        executable = 'hydra';
        // Exemple : Test de force brute[cite: 4]
        arguments = [target, options ?? 'ssh'];
        break;

      default:
        throw ArgumentError('Outil de pentesting non pris en charge : $toolName');
    }

    return {
      'executable': executable,
      'arguments': arguments,
      'full_command': '$executable ${arguments.join(' ')}',
    };
  }
}