import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class GlobalLog {
  final String id;
  final String timestamp;
  final String category; // SYSTEM, SECURITY, NETWORK
  final String severity; // INFO, WARNING, CRITICAL
  final String message;
  final String hash; // Signature cryptographique

  GlobalLog(this.id, this.timestamp, this.category, this.severity, this.message, this.hash);
}

class LogCenterScreen extends StatefulWidget {
  const LogCenterScreen({super.key});

  @override
  State<LogCenterScreen> createState() => _LogCenterScreenState();
}

class _LogCenterScreenState extends State<LogCenterScreen> {
  final Color kBgColor = const Color(0xFF070B14);
  final Color kCardColor = const Color(0xFF131C2D);
  final Color kCyan = const Color(0xFF00E5FF);

  List<GlobalLog> _masterLogs = [];
  List<GlobalLog> _filteredLogs = [];
  String _searchQuery = "";
  String _selectedCategory = "ALL";

  @override
  void initState() {
    super.initState();
    _generateDummyLogs();
  }

  void _generateDummyLogs() {
    _masterLogs = [
      GlobalLog("LOG-001", "10:45:02", "SECURITY", "CRITICAL", "Brute-force SSH détecté depuis 192.168.1.50", "sha256:8f2a..."),
      GlobalLog("LOG-002", "10:44:10", "NETWORK", "WARNING", "Latence BGP élevée (150ms) sur WAN-1", "sha256:1e4b..."),
      GlobalLog("LOG-003", "10:40:00", "SYSTEM", "INFO", "Sauvegarde GitOps terminée avec succès", "sha256:9c3d..."),
      GlobalLog("LOG-004", "09:12:44", "SECURITY", "INFO", "Admin_John connecté (MFA Validé)", "sha256:7a1f..."),
      GlobalLog("LOG-005", "08:30:00", "SYSTEM", "CRITICAL", "Défaillance ventilateur Chassis-2", "sha256:4b2e..."),
    ];
    _filteredLogs = _masterLogs;
  }

  // --- ALGORYTHME DE FILTRAGE ULTRA-RAPIDE ---
  void _applyFilters() {
    setState(() {
      _filteredLogs = _masterLogs.where((log) {
        bool matchesSearch = log.message.toLowerCase().contains(_searchQuery.toLowerCase()) || log.id.contains(_searchQuery);
        bool matchesCategory = _selectedCategory == "ALL" || log.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- EN-TÊTE ---
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CENTRE DES LOGS (SIEM UNIFIÉ)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 4),
                  Text("Audit Trail cryptographiquement scellé (WORM Compliance).", style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kCyan.withValues(alpha: 0.1), foregroundColor: kCyan, elevation: 0),
                icon: const Icon(CupertinoIcons.tray_arrow_down, size: 16),
                label: const Text("Exporter CSV", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exportation Forensic démarrée."), backgroundColor: Colors.greenAccent));
                },
              )
            ],
          ),
        ),

        // --- BARRE DE RECHERCHE & FILTRES ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                  child: TextField(
                    style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(icon: Icon(CupertinoIcons.search, color: Colors.blueGrey, size: 18), hintText: "Recherche KQL (ex: SSH, BGP, LOG-001)...", hintStyle: TextStyle(color: Colors.white30), border: InputBorder.none),
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildCategoryDropdown(),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- LISTE DES LOGS (DATATABLE) ---
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _filteredLogs.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                final log = _filteredLogs[index];
                Color sevColor = log.severity == "CRITICAL" ? const Color(0xFFFF2A55) : (log.severity == "WARNING" ? Colors.orangeAccent : kCyan);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("[${log.timestamp}]", style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[400], fontSize: 12)),
                      const SizedBox(width: 16),
                      SizedBox(width: 80, child: Text(log.category, style: TextStyle(color: Colors.blueGrey[200], fontSize: 10, fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 80,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: sevColor.withValues(alpha: 0.3))),
                            child: Text(log.severity, textAlign: TextAlign.center, style: TextStyle(color: sevColor, fontSize: 9, fontWeight: FontWeight.bold)),
                          )
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text(log.message, style: const TextStyle(color: Colors.white, fontSize: 13))),
                      const SizedBox(width: 16),
                      Tooltip(
                        message: "Signature Cryptographique: ${log.hash}",
                        child: const Icon(CupertinoIcons.lock_shield_fill, color: Colors.greenAccent, size: 16),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: kCardColor,
          value: _selectedCategory,
          icon: const Icon(CupertinoIcons.chevron_down, color: Colors.blueGrey, size: 14),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          items: ["ALL", "SECURITY", "SYSTEM", "NETWORK"].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: (val) {
            setState(() { _selectedCategory = val!; _applyFilters(); });
          },
        ),
      ),
    );
  }
}