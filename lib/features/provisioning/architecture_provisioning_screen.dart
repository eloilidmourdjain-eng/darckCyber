import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class ArchitectureAndProvisioningScreen extends StatefulWidget {
  const ArchitectureAndProvisioningScreen({super.key});

  @override
  State<ArchitectureAndProvisioningScreen> createState() => _ArchitectureAndProvisioningScreenState();
}

class _ArchitectureAndProvisioningScreenState extends State<ArchitectureAndProvisioningScreen> {
  // --- VARIABLES IaC ---
  String _selectedDeviceOS = "Cisco IOS-XE";
  final TextEditingController _hostnameController = TextEditingController(text: "DP-Router-01");
  final TextEditingController _ipController = TextEditingController(text: "192.168.10.1");
  final TextEditingController _vlanController = TextEditingController(text: "10");

  bool _enableFTP = false;
  bool _enableSNMP = true;
  bool _enableDHCP = false;
  final TextEditingController _dhcpPoolName = TextEditingController(text: "DARK_PULSE_LAN");
  final TextEditingController _dhcpNetwork = TextEditingController(text: "192.168.10.0");
  bool _enableDNS = false;
  final TextEditingController _primaryDNS = TextEditingController(text: "8.8.8.8");
  final TextEditingController _secondaryDNS = TextEditingController(text: "1.1.1.1");

  // TERMINAL INTERACTIF (Remplacement de la String statique par un Controller éditable)
  final TextEditingController _scriptEditorController = TextEditingController(
      text: "// Dark Pulse Engine : En attente de configuration sécurisée...\n// Remplissez les paramètres et validez le générateur."
  );

  String _selectedArchitecture = "Réseau Hybride (LAN/WLAN)";

  // --- VARIABLES DU SIMULATEUR (GNS3 / Dry Run) ---
  bool _isSimulating = false;
  final List<String> _simulationLogs = [];
  final ScrollController _simScrollController = ScrollController();

  // ==========================================
  // MOTEUR DE GÉNÉRATION IaC SÉCURISÉ
  // ==========================================
  void _generateDarkPulseScript() {
    final RegExp ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(_ipController.text) || (_enableDHCP && !ipRegex.hasMatch(_dhcpNetwork.text))) {
      setState(() {
        _scriptEditorController.text = "! ERREUR DE SÉCURITÉ : Format d'adresse IPv4 invalide détecté.\n! Veuillez corriger les IP avant la génération.";
      });
      return;
    }

    setState(() {
      if (_selectedDeviceOS == "Cisco IOS-XE") {
        String ipBase = "192.168.10";
        if (_ipController.text.contains('.')) {
          ipBase = _ipController.text.substring(0, _ipController.text.lastIndexOf('.'));
        }

        String dhcpConfig = _enableDHCP ? '''
! --- DDI (DHCP/IPAM) Configuration ---
ip dhcp excluded-address ${_ipController.text} $ipBase.10
ip dhcp pool ${_dhcpPoolName.text}
 network ${_dhcpNetwork.text} 255.255.255.0
 default-router ${_ipController.text}
 ${_enableDNS ? 'dns-server ${_primaryDNS.text} ${_secondaryDNS.text}' : ''}
 lease 7
!''' : "";

        String dnsConfig = _enableDNS ? '''
! --- DNS Resolution ---
ip domain-name darkpulse.local
ip name-server ${_primaryDNS.text}
ip name-server ${_secondaryDNS.text}
!''' : "";

        _scriptEditorController.text = '''
! ----------------------------------------------------
! DARK PULSE ZTP AUTOMATION ENGINE (SECURE v2.6)
! Target: ${_hostnameController.text}
! Compliance: CIS Benchmark / NIST SP 800-53
! ----------------------------------------------------
enable
configure terminal

! --- L2 / L3 (Data Link & Network Layer) ---
hostname ${_hostnameController.text}
interface vlan ${_vlanController.text}
 description DARK_PULSE_MANAGED_VLAN
 ip address ${_ipController.text} 255.255.255.0
 no shutdown
exit
$dnsConfig$dhcpConfig
! --- Security Hardening (Control Plane) ---
service password-encryption
security authentication failure rate 3 log
ip ssh version 2
ip ssh server algorithm encryption aes256-gcm aes128-gcm
line vty 0 4
 transport input ssh
 login local
exit

! --- L7 Application Protocols & Télémétrie ---
${_enableFTP ? '! Alerte : FTP rejeté par politique DevSecOps (Utiliser SFTP)' : '! FTP Protocol Disabled (Security Policy)'}
${_enableSNMP ? 'snmp-server group DarkPulseGroup v3 priv read darkPulseView\n' : '! SNMP Monitoring Disabled'}

end
write memory
''';
      }
    });
  }

  // ==========================================
  // MOTEUR DE SIMULATION (DRY RUN TYPE GNS3)
  // ==========================================
  Future<void> _runSimulation() async {
    if (_scriptEditorController.text.contains("ERREUR") || _scriptEditorController.text.contains("En attente")) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez générer un script valide avant la simulation."), backgroundColor: Colors.orange));
      return;
    }

    setState(() {
      _isSimulating = true;
      _simulationLogs.clear();
      _simulationLogs.add("[SYS] Initialisation de l'environnement virtuel (Sandbox)...");
    });

    // Séquence de simulation réaliste (CI/CD Pipeline)
    final steps = [
      "[CI/CD] Parsing du script IaC généré...",
      "[CHECK] Validation de la syntaxe ${_selectedDeviceOS}... OK",
      "[GNS3] Création du noeud virtuel : ${_hostnameController.text}...",
      "[NET] Attribution IP virtuelle: ${_ipController.text}/24...",
      "[NET] Activation de l'interface Vlan${_vlanController.text} (UP)...",
      _enableDHCP ? "[DHCP] Test d'allocation IP sur le pool ${_dhcpPoolName.text}... SUCCESS" : "[DHCP] Service ignoré.",
      "[SEC] Audit de la configuration SSH et chiffrements... SECURE",
      "[PING] Test de routage interne vers 127.0.0.1... 0% Packet Loss",
      "[SUCCESS] DRUN RUN TERMINÉ. Le script est sain et prêt pour la production."
    ];

    for (String step in steps) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _simulationLogs.add(step);
      });
      _scrollToBottomSim();
    }

    setState(() => _isSimulating = false);
  }

  void _scrollToBottomSim() {
    if (_simScrollController.hasClients) {
      _simScrollController.animateTo(_simScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _scriptEditorController.dispose();
    _simScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: DefaultTabController(
          length: 3, // Passage à 3 onglets
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Dark Pulse Infrastructure', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              TabBar(
                indicatorColor: const Color(0xFF00E5FF),
                labelColor: const Color(0xFF00E5FF),
                unselectedLabelColor: Colors.blueGrey[400],
                tabs: const [
                  Tab(icon: Icon(CupertinoIcons.square_stack_3d_up), text: "Architecture"),
                  Tab(icon: Icon(Icons.code), text: "ZTP (Générateur IaC)"),
                  Tab(icon: Icon(CupertinoIcons.play_circle_fill), text: "Simulateur (GNS3 Dry-Run)"), // Nouvel Onglet
                ],
              ),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(), // Désactive le swipe pour l'éditeur de code
                  children: [
                    _buildArchitectureDesigner(),
                    _buildScriptGenerator(),
                    _buildSimulatorTab(), // Nouvel Onglet
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ONGLET 1 : DESIGNER (COMPACT & ACTIONS)
  // ==========================================
  Widget _buildArchitectureDesigner() {
    final architectures = [
      {"name": "LAN (Local)", "icon": CupertinoIcons.building_2_fill, "desc": "Couche 2/3. Câblé."},
      {"name": "WLAN (Sans-fil)", "icon": CupertinoIcons.wifi, "desc": "Réseau mobile, WPA3."},
      {"name": "VLAN (Virtuel)", "icon": CupertinoIcons.layers_fill, "desc": "Segmentation logique L2."},
      {"name": "PAN (Personnel)", "icon": CupertinoIcons.device_laptop, "desc": "Bluetooth/IoT (Courte portée)."},
      {"name": "MAN (Métro)", "icon": CupertinoIcons.map_fill, "desc": "Liaisons fibre optique inter-sites."},
      {"name": "Réseau Maillé", "icon": CupertinoIcons.link, "desc": "Haute résilience. AIOps."},
      {"name": "Réseau Hybride", "icon": CupertinoIcons.arrow_merge, "desc": "Mix LAN/WLAN (Recommandé)."},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Modélisation Topologique", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.cyanAccent, side: const BorderSide(color: Colors.cyanAccent)),
                    icon: const Icon(CupertinoIcons.cloud_download, size: 16),
                    label: const Text("Charger Template", style: TextStyle(fontSize: 12)),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white),
                    icon: const Icon(CupertinoIcons.floppy_disk, size: 16),
                    label: const Text("Sauvegarder", style: TextStyle(fontSize: 12)),
                    onPressed: () {},
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800 ? 3 : 2; // Grille Responsive
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 3.5, // Ratio rendu plus compact !
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: architectures.length,
                  itemBuilder: (context, index) {
                    final arch = architectures[index];
                    bool isSelected = _selectedArchitecture == arch["name"];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedArchitecture = arch["name"] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.1) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? const Color(0xFF00E5FF) : Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Icon(arch["icon"] as IconData, color: isSelected ? const Color(0xFF00E5FF) : Colors.blueGrey[400], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(arch["name"] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(arch["desc"] as String, style: TextStyle(color: Colors.blueGrey[400], fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 2 : GÉNÉRATEUR IaC & TERMINAL INTERACTIF
  // ==========================================
  Widget _buildScriptGenerator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;
            return Flex(
              direction: isDesktop ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COLONNE GAUCHE (Formulaire compacté)
                Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDropdown("OS Cible", ["Cisco IOS-XE", "Ansible Playbook (YAML)"], _selectedDeviceOS, (val) => setState(() => _selectedDeviceOS = val!)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField("Hostname", _hostnameController)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildInputField("VLAN ID", _vlanController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInputField("Adresse IP Locale", _ipController),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white12)),

                      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text("Serveur DHCP", style: TextStyle(color: Colors.white70, fontSize: 13)), value: _enableDHCP, activeTrackColor: const Color(0xFF00E5FF), onChanged: (val) => setState(() => _enableDHCP = val)),
                      if (_enableDHCP) ...[
                        Row(
                          children: [
                            Expanded(child: _buildInputField("Nom Pool", _dhcpPoolName)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField("Réseau", _dhcpNetwork)),
                          ],
                        ),
                      ],
                      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text("Serveurs DNS", style: TextStyle(color: Colors.white70, fontSize: 13)), value: _enableDNS, activeTrackColor: const Color(0xFF00E5FF), onChanged: (val) => setState(() => _enableDNS = val)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          icon: const Icon(CupertinoIcons.gear_alt_fill, color: Colors.white, size: 18),
                          label: const Text("Générer Script", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: _generateDarkPulseScript,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDesktop) const SizedBox(width: 24),

                // COLONNE DROITE : TERMINAL INTERACTIF ÉDITABLE
                Expanded(
                  flex: isDesktop ? 2 : 0,
                  child: Container(
                    height: isDesktop ? 600 : 400,
                    margin: EdgeInsets.only(top: isDesktop ? 0 : 24),
                    decoration: BoxDecoration(color: const Color(0xFF000000), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3))),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(CupertinoIcons.circle_fill, color: Colors.redAccent, size: 10), SizedBox(width: 6),
                                  Icon(CupertinoIcons.circle_fill, color: Colors.orangeAccent, size: 10), SizedBox(width: 6),
                                  Icon(CupertinoIcons.circle_fill, color: Colors.greenAccent, size: 10), SizedBox(width: 12),
                                  Text("Éditeur Interactif (Modifiable)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                              Icon(CupertinoIcons.pencil, color: Colors.blueGrey[400], size: 16)
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: TextField(
                              controller: _scriptEditorController,
                              maxLines: null, // Permet un nombre de lignes infini (Editeur de code)
                              keyboardType: TextInputType.multiline,
                              style: GoogleFonts.jetBrainsMono(color: const Color(0xFF00E5FF), fontSize: 13, height: 1.5),
                              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            );
          }
      ),
    );
  }

  // ==========================================
  // ONGLET 3 : SIMULATEUR (GNS3 / PACKET TRACER)
  // ==========================================
  Widget _buildSimulatorTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Environnement de Simulation (Dry-Run)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("Validation CI/CD : Testez la configuration avant de l'injecter dans le matériel physique.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.withValues(alpha: 0.2), foregroundColor: Colors.greenAccent, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                icon: _isSimulating ? const CupertinoActivityIndicator(color: Colors.greenAccent) : const Icon(CupertinoIcons.play_fill),
                label: Text(_isSimulating ? "Simulation..." : "EXÉCUTER LE TEST", style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _isSimulating ? null : _runSimulation,
              )
            ],
          ),
          const SizedBox(height: 24),

          // Représentation visuelle de la topologie
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTopologyNode(CupertinoIcons.cloud, "WAN / Internet", Colors.blueGrey),
                _buildTopologyLink(),
                _buildTopologyNode(CupertinoIcons.rocket_fill, _hostnameController.text, const Color(0xFF8B5CF6), ip: _ipController.text),
                _buildTopologyLink(isActive: _enableDHCP),
                _buildTopologyNode(CupertinoIcons.device_laptop, "Virtual Client", _enableDHCP ? Colors.greenAccent : Colors.blueGrey, ip: _enableDHCP ? "DHCP Auto" : "Offline"),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Console de résultat de simulation
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF000000), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: ListView.builder(
                controller: _simScrollController,
                itemCount: _simulationLogs.length,
                itemBuilder: (context, index) {
                  String log = _simulationLogs[index];
                  Color logColor = Colors.white70;
                  if (log.contains("[SUCCESS]") || log.contains("SUCCESS")) logColor = Colors.greenAccent;
                  if (log.contains("[SEC]") || log.contains("SECURE")) logColor = const Color(0xFF00E5FF);
                  if (log.contains("ERREUR") || log.contains("FAIL")) logColor = Colors.redAccent;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(log, style: GoogleFonts.jetBrainsMono(color: logColor, fontSize: 13)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS UTILITAIRES ---
  Widget _buildTopologyNode(IconData icon, String label, Color color, {String? ip}) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.5))), child: Icon(icon, color: color, size: 32)),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        if (ip != null) Text(ip, style: GoogleFonts.jetBrainsMono(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildTopologyLink({bool isActive = true}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: isActive ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.white10,
        child: isActive ? const Center(child: Icon(CupertinoIcons.chevron_right, color: Colors.greenAccent, size: 12)) : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(isExpanded: true, dropdownColor: const Color(0xFF1E293B), value: value, style: const TextStyle(color: Colors.white, fontSize: 12), items: items.map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: onChanged),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
      child: TextField(controller: controller, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.blueGrey[400], fontSize: 10), border: InputBorder.none, isDense: true)),
    );
  }
}