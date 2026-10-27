import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ArchitectureAndProvisioningScreen extends StatefulWidget {
  const ArchitectureAndProvisioningScreen({super.key});

  @override
  State<ArchitectureAndProvisioningScreen> createState() =>
      _ArchitectureAndProvisioningScreenState();
}

class _ArchitectureAndProvisioningScreenState
    extends State<ArchitectureAndProvisioningScreen> {
  static const Color _background = Color(0xFF0F172A);
  static const Color _card = Color(0xFF1E293B);
  static const Color _accent = Color(0xFF00E5FF);

  String _selectedDeviceOS = 'Cisco IOS-XE';
  String _selectedArchitecture = 'Réseau Hybride (LAN/WLAN)';

  final TextEditingController _hostnameController =
  TextEditingController(text: 'DP-Router-01');
  final TextEditingController _ipController =
  TextEditingController(text: '192.168.10.1');
  final TextEditingController _vlanController =
  TextEditingController(text: '10');

  bool _enableSNMP = true;

  bool _enableDHCP = false;
  final TextEditingController _dhcpPoolName =
  TextEditingController(text: 'DARK_PULS_LAN');
  final TextEditingController _dhcpNetwork =
  TextEditingController(text: '192.168.10.0');

  bool _enableDNS = false;
  final TextEditingController _primaryDNS =
  TextEditingController(text: '8.8.8.8');
  final TextEditingController _secondaryDNS =
  TextEditingController(text: '1.1.1.1');

  final TextEditingController _scriptEditorController =
  TextEditingController(
    text: '// Dark Puls : remplis les paramètres, '
        'puis génère une configuration.',
  );

  bool _isChecking = false;
  final List<String> _checkLogs = [];
  final ScrollController _checkScrollController = ScrollController();

  String? _generatedScript;
  String? _validationError;

  @override
  void dispose() {
    _hostnameController.dispose();
    _ipController.dispose();
    _vlanController.dispose();
    _dhcpPoolName.dispose();
    _dhcpNetwork.dispose();
    _primaryDNS.dispose();
    _secondaryDNS.dispose();
    _scriptEditorController.dispose();
    _checkScrollController.dispose();
    super.dispose();
  }

  // ==========================================================
  // VALIDATION
  // ==========================================================

  bool _isValidIpv4(String value) {
    final parts = value.trim().split('.');

    if (parts.length != 4) return false;

    return parts.every((part) {
      if (!RegExp(r'^\d{1,3}$').hasMatch(part)) return false;

      final number = int.tryParse(part);
      return number != null && number >= 0 && number <= 255;
    });
  }

  bool _isValidHostname(String value) {
    return RegExp(
      r'^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$',
    ).hasMatch(value.trim());
  }

  bool _isValidVlan(String value) {
    final vlan = int.tryParse(value.trim());
    return vlan != null && vlan >= 1 && vlan <= 4094;
  }

  bool _isValidPoolName(String value) {
    return RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(value.trim());
  }

  String? _validateInputs() {
    if (!_isValidHostname(_hostnameController.text)) {
      return 'Nom d’hôte invalide. Utilise des lettres, chiffres '
          'ou tirets, sans espace.';
    }

    if (!_isValidIpv4(_ipController.text)) {
      return 'Adresse IP locale invalide.';
    }

    if (!_isValidVlan(_vlanController.text)) {
      return 'VLAN invalide. Utilise une valeur entre 1 et 4094.';
    }

    if (_enableDHCP) {
      if (!_isValidPoolName(_dhcpPoolName.text)) {
        return 'Nom du pool DHCP invalide.';
      }

      if (!_isValidIpv4(_dhcpNetwork.text)) {
        return 'Réseau DHCP invalide.';
      }
    }

    if (_enableDNS) {
      if (!_isValidIpv4(_primaryDNS.text)) {
        return 'DNS primaire invalide.';
      }

      if (!_isValidIpv4(_secondaryDNS.text)) {
        return 'DNS secondaire invalide.';
      }
    }

    return null;
  }

  // ==========================================================
  // GÉNÉRATION
  // ==========================================================

  void _generateConfiguration() {
    final error = _validateInputs();

    if (error != null) {
      setState(() {
        _validationError = error;
        _generatedScript = null;
        _scriptEditorController.text =
        '! Configuration non générée.\n! Erreur : $error';
      });
      return;
    }

    final String script;

    if (_selectedDeviceOS == 'Cisco IOS-XE') {
      script = _generateCiscoConfig();
    } else {
      script = _generateAnsiblePlaybook();
    }

    setState(() {
      _validationError = null;
      _generatedScript = script;
      _scriptEditorController.text = script;
      _checkLogs.clear();
    });
  }

  String _generateCiscoConfig() {
    final hostname = _hostnameController.text.trim();
    final ip = _ipController.text.trim();
    final vlan = _vlanController.text.trim();

    final ipPrefix =
    ip.substring(0, ip.lastIndexOf('.'));

    final buffer = StringBuffer()
      ..writeln('! Configuration générée par Dark Puls')
      ..writeln('! Cible : Cisco IOS-XE')
      ..writeln('! À vérifier et adapter avant tout déploiement.')
      ..writeln('enable')
      ..writeln('configure terminal')
      ..writeln()
      ..writeln('hostname $hostname')
      ..writeln()
      ..writeln('interface Vlan$vlan')
      ..writeln(' description Interface administrée par Dark Puls')
      ..writeln(' ip address $ip 255.255.255.0')
      ..writeln(' no shutdown')
      ..writeln(' exit')
      ..writeln();

    if (_enableDNS) {
      buffer
        ..writeln('ip name-server ${_primaryDNS.text.trim()}')
        ..writeln('ip name-server ${_secondaryDNS.text.trim()}')
        ..writeln();
    }

    if (_enableDHCP) {
      buffer
        ..writeln('ip dhcp excluded-address $ip')
        ..writeln('ip dhcp excluded-address $ipPrefix.10')
        ..writeln(
          'ip dhcp pool ${_dhcpPoolName.text.trim()}',
        )
        ..writeln(
          ' network ${_dhcpNetwork.text.trim()} 255.255.255.0',
        )
        ..writeln(' default-router $ip');

      if (_enableDNS) {
        buffer.writeln(
          ' dns-server ${_primaryDNS.text.trim()} '
              '${_secondaryDNS.text.trim()}',
        );
      }

      buffer
        ..writeln(' lease 7')
        ..writeln(' exit')
        ..writeln();
    }

    buffer
      ..writeln('service password-encryption')
      ..writeln('ip ssh version 2')
      ..writeln('line vty 0 4')
      ..writeln(' transport input ssh')
      ..writeln(' login local')
      ..writeln(' exit');

    if (_enableSNMP) {
      buffer
        ..writeln()
        ..writeln('! SNMPv3 : remplace les identifiants avant usage.')
        ..writeln(
          'snmp-server group DARKPULS-RO v3 priv '
              'read DARKPULS-VIEW',
        )
        ..writeln(
          'snmp-server view DARKPULS-VIEW iso included',
        );
    } else {
      buffer
        ..writeln()
        ..writeln('! SNMP non activé dans cette configuration.');
    }

    buffer
      ..writeln()
      ..writeln('end')
      ..writeln('write memory');

    return buffer.toString();
  }

  String _generateAnsiblePlaybook() {
    final hostname = _hostnameController.text.trim();
    final ip = _ipController.text.trim();
    final vlan = _vlanController.text.trim();

    final buffer = StringBuffer()
      ..writeln('# Playbook généré par Dark Puls')
      ..writeln('# À adapter à ton inventaire et à tester.')
      ..writeln('---')
      ..writeln('- name: Configurer l’équipement cible')
      ..writeln('  hosts: network_devices')
      ..writeln('  gather_facts: false')
      ..writeln('  vars:')
      ..writeln('    hostname: $hostname')
      ..writeln('    management_ip: $ip')
      ..writeln('    vlan_id: $vlan')
      ..writeln()
      ..writeln('  tasks:')
      ..writeln(
        '    - name: Définir le nom d’hôte',
      )
      ..writeln('      cisco.ios.ios_config:')
      ..writeln('        lines:')
      ..writeln('          - hostname {{ hostname }}')
      ..writeln()
      ..writeln(
        '    - name: Configurer l’interface VLAN',
      )
      ..writeln('      cisco.ios.ios_config:')
      ..writeln('        lines:')
      ..writeln(
        '          - interface Vlan{{ vlan_id }}',
      )
      ..writeln(
        '          - ip address {{ management_ip }} '
            '255.255.255.0',
      )
      ..writeln('          - no shutdown');

    if (_enableDNS) {
      buffer
        ..writeln()
        ..writeln(
          '    - name: Configurer les serveurs DNS',
        )
        ..writeln('      cisco.ios.ios_config:')
        ..writeln('        lines:')
        ..writeln(
          '          - ip name-server '
              '${_primaryDNS.text.trim()}',
        )
        ..writeln(
          '          - ip name-server '
              '${_secondaryDNS.text.trim()}',
        );
    }

    if (_enableDHCP) {
      buffer
        ..writeln()
        ..writeln(
          '    - name: Configurer le pool DHCP',
        )
        ..writeln('      cisco.ios.ios_config:')
        ..writeln('        lines:')
        ..writeln(
          '          - ip dhcp pool '
              '${_dhcpPoolName.text.trim()}',
        )
        ..writeln(
          '          - network ${_dhcpNetwork.text.trim()} '
              '255.255.255.0',
        )
        ..writeln(
          '          - default-router {{ management_ip }}',
        );
    }

    return buffer.toString();
  }

  // ==========================================================
  // VÉRIFICATION STATIQUE
  // ==========================================================

  Future<void> _runStaticCheck() async {
    if (_isChecking) return;

    final script = _scriptEditorController.text.trim();

    if (script.isEmpty) {
      _notify('Aucun script à vérifier.');
      return;
    }

    setState(() {
      _isChecking = true;
      _checkLogs.clear();
      _validationError = null;
    });

    Future<void> addLog(String message) async {
      await Future.delayed(const Duration(milliseconds: 250));

      if (!mounted) return;

      setState(() {
        _checkLogs.add(message);
      });

      _scrollToBottom();
    }

    try {
      await addLog(
        '[VÉRIFICATION] Lecture du script affiché...',
      );

      if (script.contains('Configuration non générée')) {
        await addLog(
          '[ÉCHEC] Le script contient une erreur de génération.',
        );
        return;
      }

      if (_selectedDeviceOS == 'Cisco IOS-XE') {
        final requiredLines = [
          'configure terminal',
          'hostname ',
          'interface Vlan',
          'ip address ',
        ];

        for (final line in requiredLines) {
          if (!script.contains(line)) {
            await addLog(
              '[ÉCHEC] Élément attendu absent : "$line".',
            );
            return;
          }
        }

        await addLog(
          '[OK] Éléments Cisco essentiels présents.',
        );

        if (script.contains('ip dhcp pool')) {
          await addLog(
            '[OK] Bloc DHCP détecté.',
          );
        }

        if (script.contains('ip name-server')) {
          await addLog(
            '[OK] Serveurs DNS détectés.',
          );
        }

        if (script.contains('line vty 0 4') &&
            script.contains('transport input ssh')) {
          await addLog(
            '[OK] Accès VTY limité à SSH détecté.',
          );
        }
      } else {
        if (!script.startsWith('---')) {
          await addLog(
            '[ÉCHEC] Le playbook ne commence pas par "---".',
          );
          return;
        }

        if (!script.contains('hosts:')) {
          await addLog(
            '[ÉCHEC] Cible "hosts:" absente du playbook.',
          );
          return;
        }

        if (!script.contains('tasks:')) {
          await addLog(
            '[ÉCHEC] Section "tasks:" absente du playbook.',
          );
          return;
        }

        await addLog(
          '[OK] Structure YAML minimale détectée.',
        );
      }

      await addLog(
        '[INFO] Vérification statique terminée. '
            'Aucun équipement n’a été contacté.',
      );
      await addLog(
        '[INFO] Cette vérification ne remplace pas un test '
            'sur un laboratoire réel.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (!_checkScrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_checkScrollController.hasClients) return;

      _checkScrollController.animateTo(
        _checkScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _notify(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ==========================================================
  // INTERFACE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Dark Puls — Architecture et provisioning',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              TabBar(
                indicatorColor: _accent,
                labelColor: _accent,
                unselectedLabelColor: Colors.blueGrey,
                tabs: const [
                  Tab(
                    icon: Icon(
                      CupertinoIcons.square_stack_3d_up,
                    ),
                    text: 'Architecture',
                  ),
                  Tab(
                    icon: Icon(Icons.code),
                    text: 'Générateur',
                  ),
                  Tab(
                    icon: Icon(Icons.rule),
                    text: 'Vérification',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildArchitectureTab(),
                    _buildGeneratorTab(),
                    _buildCheckTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchitectureTab() {
    final architectures = [
      {
        'name': 'LAN (Local)',
        'icon': CupertinoIcons.building_2_fill,
        'desc': 'Réseau local filaire',
      },
      {
        'name': 'WLAN (Sans-fil)',
        'icon': CupertinoIcons.wifi,
        'desc': 'Réseau sans fil',
      },
      {
        'name': 'VLAN (Virtuel)',
        'icon': CupertinoIcons.layers_fill,
        'desc': 'Segmentation logique',
      },
      {
        'name': 'Réseau Maillé',
        'icon': CupertinoIcons.link,
        'desc': 'Plusieurs chemins possibles',
      },
      {
        'name': 'Réseau Hybride',
        'icon': CupertinoIcons.arrow_merge,
        'desc': 'LAN et WLAN combinés',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choix d’architecture',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ce choix est enregistré comme contexte de conception. '
                'Il ne modifie pas automatiquement la configuration.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
              constraints.maxWidth > 800 ? 3 : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: 3.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: architectures.length,
                itemBuilder: (context, index) {
                  final architecture = architectures[index];
                  final name = architecture['name'] as String;
                  final selected =
                      _selectedArchitecture == name;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedArchitecture = name;
                      });
                    },
                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? _accent.withValues(alpha: 0.1)
                            : _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? _accent
                              : Colors.white10,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            architecture['icon'] as IconData,
                            color: selected
                                ? _accent
                                : Colors.blueGrey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  architecture['desc'] as String,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          final form = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown(
                'Format de sortie',
                const [
                  'Cisco IOS-XE',
                  'Ansible Playbook (YAML)',
                ],
                _selectedDeviceOS,
                    (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDeviceOS = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      'Nom d’hôte',
                      _hostnameController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      'VLAN',
                      _vlanController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInputField(
                'Adresse IP locale',
                _ipController,
              ),
              const Divider(color: Colors.white12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Activer SNMPv3',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                value: _enableSNMP,
                onChanged: (value) {
                  setState(() {
                    _enableSNMP = value;
                  });
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Activer DHCP',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                value: _enableDHCP,
                onChanged: (value) {
                  setState(() {
                    _enableDHCP = value;
                  });
                },
              ),
              if (_enableDHCP) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        'Nom du pool',
                        _dhcpPoolName,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        'Réseau DHCP',
                        _dhcpNetwork,
                      ),
                    ),
                  ],
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Activer les serveurs DNS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                value: _enableDNS,
                onChanged: (value) {
                  setState(() {
                    _enableDNS = value;
                  });
                },
              ),
              if (_enableDNS) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        'DNS primaire',
                        _primaryDNS,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        'DNS secondaire',
                        _secondaryDNS,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _generateConfiguration,
                  icon: const Icon(Icons.build),
                  label: const Text('Générer la configuration'),
                ),
              ),
              if (_validationError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _validationError!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ],
          );

          final editor = Container(
            height: isDesktop ? 600 : 420,
            margin: EdgeInsets.only(top: isDesktop ? 0 : 24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _accent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Configuration générée — modifiable',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copier',
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text:
                              _scriptEditorController.text,
                            ),
                          );
                          _notify('Configuration copiée.');
                        },
                        icon: const Icon(
                          Icons.copy,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _scriptEditorController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: GoogleFonts.jetBrainsMono(
                        color: _accent,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: editor),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [form, editor],
          );
        },
      ),
    );
  }

  Widget _buildCheckTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vérification statique de la configuration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cette fonction analyse le texte affiché dans '
                'l’éditeur. Elle ne contacte aucun équipement et '
                'n’exécute pas GNS3.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _isChecking
                    ? null
                    : _runStaticCheck,
                icon: _isChecking
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.rule),
                label: Text(
                  _isChecking
                      ? 'Vérification...'
                      : 'Vérifier le script',
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _generatedScript == null
                    ? null
                    : () {
                  setState(() {
                    _scriptEditorController.text =
                    _generatedScript!;
                    _checkLogs.clear();
                  });
                },
                child: const Text(
                  'Restaurer la version générée',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _checkLogs.isEmpty
                  ? const Center(
                child: Text(
                  'Aucune vérification exécutée.',
                  style: TextStyle(color: Colors.white38),
                ),
              )
                  : ListView.builder(
                controller: _checkScrollController,
                itemCount: _checkLogs.length,
                itemBuilder: (context, index) {
                  final log = _checkLogs[index];

                  Color color = Colors.white70;

                  if (log.startsWith('[OK]')) {
                    color = Colors.greenAccent;
                  } else if (log.startsWith('[ÉCHEC]')) {
                    color = Colors.redAccent;
                  } else if (log.startsWith('[INFO]')) {
                    color = Colors.white54;
                  }

                  return Padding(
                    padding:
                    const EdgeInsets.only(bottom: 6),
                    child: SelectableText(
                      log,
                      style: GoogleFonts.jetBrainsMono(
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      List<String> items,
      String value,
      ValueChanged<String?> onChanged,
      ) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: _card,
          value: value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            ),
          )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label,
      TextEditingController controller,
      ) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _card,
        labelStyle: const TextStyle(
          color: Colors.blueGrey,
          fontSize: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
    );
  }
}