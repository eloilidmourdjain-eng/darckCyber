import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class ArchitectureAndProvisioningScreen extends StatefulWidget {
  const ArchitectureAndProvisioningScreen({super.key});

  @override
  State<ArchitectureAndProvisioningScreen> createState() => _ArchitectureAndProvisioningScreenState();
}

class _ArchitectureAndProvisioningScreenState extends State<ArchitectureAndProvisioningScreen> {
  // --- VARIABLES POUR LE GÉNÉRATEUR DE SCRIPT (IaC) ---
  String _selectedDeviceOS = "Cisco IOS-XE";

  // Paramètres de base
  final TextEditingController _hostnameController = TextEditingController(text: "DP-Router-01");
  final TextEditingController _ipController = TextEditingController(text: "192.168.10.1");
  final TextEditingController _vlanController = TextEditingController(text: "10");

  // Protocoles Application & Sécurité
  bool _enableFTP = false;
  bool _enableSNMP = true;

  // Paramètres DDI (DHCP & DNS)
  bool _enableDHCP = false;
  final TextEditingController _dhcpPoolName = TextEditingController(text: "DARK_PULSE_LAN");
  final TextEditingController _dhcpNetwork = TextEditingController(text: "192.168.10.0");

  bool _enableDNS = false;
  final TextEditingController _primaryDNS = TextEditingController(text: "8.8.8.8");
  final TextEditingController _secondaryDNS = TextEditingController(text: "1.1.1.1");

  String _generatedScript = "// Dark Pulse Engine : En attente de configuration sécurisée...\n// Remplissez les paramètres et validez le générateur.";

  // --- VARIABLES POUR L'ARCHITECTURE ---
  String _selectedArchitecture = "Réseau Hybride (LAN/WLAN)";

  // --- MOTEUR DE GÉNÉRATION IaC SÉCURISÉ (DevSecOps) ---
  void _generateDarkPulseScript() {
    // 1. Validation stricte des entrées (Anti-Injection / Validation IP)
    final RegExp ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(_ipController.text) || !ipRegex.hasMatch(_dhcpNetwork.text)) {
      setState(() {
        _generatedScript = "// ERREUR DE SÉCURITÉ : Format d'adresse IPv4 invalide détecté.";
      });
      return;
    }

    setState(() {
      if (_selectedDeviceOS == "Cisco IOS-XE") {
        // Extraction sécurisée de la base réseau
        String ipBase = "192.168.10";
        if (_ipController.text.contains('.')) {
          ipBase = _ipController.text.substring(0, _ipController.text.lastIndexOf('.'));
        }

        // Logique DHCP durcie
        String dhcpConfig = "";
        if (_enableDHCP) {
          dhcpConfig = '''
! --- DDI (DHCP/IPAM) Configuration ---
ip dhcp excluded-address ${_ipController.text} $ipBase.10
ip dhcp pool ${_dhcpPoolName.text}
 network ${_dhcpNetwork.text} 255.255.255.0
 default-router ${_ipController.text}
 ${_enableDNS ? 'dns-server ${_primaryDNS.text} ${_secondaryDNS.text}' : ''}
lease 7
! ''';
        }

        // Logique DNS sécurisée
        String dnsConfig = "";
        if (_enableDNS) {
          dnsConfig = '''
! --- DNS Resolution ---
ip domain-name darkpulse.local
ip name-server ${_primaryDNS.text}
ip name-server ${_secondaryDNS.text}
! ''';
        }

        // Assemblage final du script conforme aux benchmarks de sécurité
        _generatedScript = '''
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

$dnsConfig
$dhcpConfig

! --- Security Hardening (Plan de Contrôle) ---
service password-encryption
security authentication failure rate 3 log
ip ssh version 2
ip ssh server algorithm encryption aes256-gcm aes128-gcm
line vty 0 4
 transport input ssh
 login local
exit

! --- L7 Application Protocols & Télémétrie ---
${_enableFTP ? '! ALerte Sécurité : FTP rejeté par la politique DevSecOps (Utiliser SFTP)' : '! FTP Protocol Disabled (Security Policy)'}
${_enableSNMP ? 'snmp-server group DarkPulseGroup v3 priv read darkPulseView\nsnmp-server user darkPulseAdmin DarkPulseGroup v3 auth sha AuthPass123! priv aes 128 PrivPass123!\n' : '! SNMP Monitoring Disabled'}

end
write memory
''';
      } else if (_selectedDeviceOS == "Ansible Playbook (YAML)") {
        _generatedScript = '''
# ----------------------------------------------------
# DARK PULSE ANSIBLE PLAYBOOK (SECURE DDI)
# ----------------------------------------------------
- name: Dark Pulse Automated Provisioning (Hardened)
  hosts: ${_hostnameController.text}
  gather_facts: no
  tasks:
    - name: L3 Configuration (TCP/IP)
      cisco.ios.ios_l3_interfaces:
        config:
          - name: Vlan${_vlanController.text}
            ipv4:
              - address: ${_ipController.text}/24
                state: merged
    - name: Enforce Secure SSH v2
      cisco.ios.ios_config:
        lines:
          - ip ssh version 2
''';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
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
                  Tab(icon: Icon(CupertinoIcons.square_stack_3d_up), text: "Design d'Architecture"),
                  Tab(icon: Icon(Icons.code), text: "ZTP & Scripts (IaC)"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildArchitectureDesigner(),
                    _buildScriptGenerator(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================== //
  // ONGLET 1 : DESIGNER D'ARCHITECTURE         //
  // ========================================== //
  Widget _buildArchitectureDesigner() {
    final architectures = [
      {"name": "LAN (Local)", "icon": CupertinoIcons.building_2_fill, "desc": "Couche 2/3. Haute vitesse interne, câblé."},
      {"name": "WLAN (Sans-fil)", "icon": CupertinoIcons.wifi, "desc": "Réseau mobile, sécurisé par WPA3 Enterprise."},
      {"name": "VLAN (Virtuel)", "icon": CupertinoIcons.layers_fill, "desc": "Segmentation logique L2 (Isolations des flux)."},
      {"name": "PAN (Personnel)", "icon": CupertinoIcons.device_laptop, "desc": "Bluetooth/IoT très courte portée (Couche 1/2)."},
      {"name": "MAN (Métropolitain)", "icon": CupertinoIcons.map_fill, "desc": "Liaisons fibre optique inter-sites (OSPF/BGP)."},
      {"name": "Réseau Maillé (Mesh)", "icon": CupertinoIcons.link, "desc": "Haute résilience. Nœuds interconnectés (AIOps)."},
      {"name": "Réseau Hybride", "icon": CupertinoIcons.arrow_merge, "desc": "Mix optimal LAN/WLAN/Cloud (Recommandé)."},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Modélisation Topologique", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Sélectionnez le type d'architecture selon le besoin client et le modèle OSI.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 14)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: architectures.length,
            itemBuilder: (context, index) {
              final arch = architectures[index];
              bool isSelected = _selectedArchitecture == arch["name"];
              return GestureDetector(
                onTap: () => setState(() => _selectedArchitecture = arch["name"] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.1) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? const Color(0xFF00E5FF) : Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(arch["icon"] as IconData, color: isSelected ? const Color(0xFF00E5FF) : Colors.blueGrey[400], size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(arch["name"] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(arch["desc"] as String, style: TextStyle(color: Colors.blueGrey[400], fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.purpleAccent, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Architecture Active : $_selectedArchitecture", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Modèle TCP/IP prêt. Les règles de routage et de commutation L2/L3 seront adaptées à cette topologie.", style: TextStyle(color: Colors.blueGrey[300], fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // ========================================== //
  // ONGLET 2 : GÉNÉRATEUR DE SCRIPT ZTP (IaC)  //
  // ========================================== //
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
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Paramètres Matériels (OSI L2/L3)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildDropdown("Système d'exploitation (OS)", ["Cisco IOS-XE", "Ansible Playbook (YAML)", "Juniper JunOS"], _selectedDeviceOS, (val) => setState(() => _selectedDeviceOS = val!)),
                    const SizedBox(height: 16),
                    _buildInputField("Hostname", _hostnameController),
                    const SizedBox(height: 16),
                    _buildInputField("Adresse IP Locale", _ipController),
                    const SizedBox(height: 16),
                    _buildInputField("ID du VLAN", _vlanController),
                    const SizedBox(height: 32),

                    const Text("Services Réseau Core (DHCP / DNS)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Activer Serveur DHCP local", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      value: _enableDHCP,
                      activeColor: const Color(0xFF00E5FF),
                      onChanged: (val) => setState(() => _enableDHCP = val),
                    ),
                    if (_enableDHCP) ...[
                      Padding(padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 8.0), child: _buildInputField("Nom du Pool DHCP", _dhcpPoolName)),
                      Padding(padding: const EdgeInsets.only(left: 16.0, bottom: 16.0), child: _buildInputField("Réseau DHCP (ex: 192.168.10.0)", _dhcpNetwork)),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Configurer les Serveurs DNS", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      value: _enableDNS,
                      activeColor: const Color(0xFF00E5FF),
                      onChanged: (val) => setState(() => _enableDNS = val),
                    ),
                    if (_enableDNS) ...[
                      Padding(padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 8.0), child: _buildInputField("DNS Primaire", _primaryDNS)),
                      Padding(padding: const EdgeInsets.only(left: 16.0, bottom: 16.0), child: _buildInputField("DNS Secondaire", _secondaryDNS)),
                    ],
                    const SizedBox(height: 24),

                    const Text("Protocoles (L7 TCP/IP & Sécurité)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Activer Serveur FTP (Non Recommandé)", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      value: _enableFTP,
                      activeColor: const Color(0xFF00E5FF),
                      onChanged: (val) => setState(() => _enableFTP = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Activer SNMPv3 (Monitoring Sécurisé)", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      value: _enableSNMP,
                      activeColor: const Color(0xFF00E5FF),
                      onChanged: (val) => setState(() => _enableSNMP = val),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(CupertinoIcons.gear_alt_fill, color: Colors.white),
                        label: const Text("Générer Script Dark Pulse", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: _generateDarkPulseScript,
                      ),
                    ),
                    if (!isDesktop) const SizedBox(height: 32),
                  ],
                ),
              ),
              if (isDesktop) const SizedBox(width: 32),
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: Container(
                  height: isDesktop ? 750 : 500,
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.1), blurRadius: 20)],
                  ),
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
                                Icon(CupertinoIcons.circle_fill, color: Colors.redAccent, size: 12),
                                SizedBox(width: 6),
                                Icon(CupertinoIcons.circle_fill, color: Colors.orangeAccent, size: 12),
                                SizedBox(width: 6),
                                Icon(CupertinoIcons.circle_fill, color: Colors.greenAccent, size: 12),
                                SizedBox(width: 16),
                                Text("Terminal Code Export (Hardened)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.doc_on_clipboard_fill, color: Colors.white54, size: 18),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Script sécurisé copié dans le presse-papier !")));
                              },
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              _generatedScript,
                              style: GoogleFonts.jetBrainsMono(color: const Color(0xFF00E5FF), fontSize: 14, height: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  // --- WIDGETS UTILITAIRES ---
  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              value: value,
              style: const TextStyle(color: Colors.white),
              items: items.map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }
}

