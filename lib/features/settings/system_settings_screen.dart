import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final Color kCardColor = const Color(0xFF131C2D);
  final Color kCyan = const Color(0xFF00E5FF);

  // États des paramètres (Control Plane)
  bool _forceMfa = true;
  bool _enableSyslogForwarding = false;
  bool _enableSlackWebhooks = true;
  double _logRetentionDays = 90;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text("CONFIGURATION SYSTÈME (GLOBAL SETTINGS)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Text("Politiques de sécurité, de rétention et d'intégration tierce (Webhooks).", style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
        const SizedBox(height: 32),

        // --- SECTION 1 : SÉCURITÉ & IAM ---
        _buildSectionHeader(CupertinoIcons.lock_shield_fill, "Sécurité & Accès (IAM)"),
        _buildSettingsCard([
          _buildSwitchRow("Forcer le MFA (2FA) pour tous les administrateurs", "Conformité Zero Trust.", _forceMfa, (v) => setState(() => _forceMfa = v)),
          const Divider(color: Colors.white12, height: 24),
          _buildActionRow("Expiration de Session (Idle Timeout)", "15 Minutes", CupertinoIcons.timer),
        ]),
        const SizedBox(height: 32),

        // --- SECTION 2 : RÉTENTION DES DONNÉES (COMPLIANCE) ---
        _buildSectionHeader(CupertinoIcons.archivebox_fill, "Rétention des Logs (Compliance)"),
        _buildSettingsCard([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Durée de conservation (Data Lake)", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              Text("${_logRetentionDays.toInt()} Jours", style: GoogleFonts.jetBrainsMono(color: kCyan, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _logRetentionDays,
            min: 7, max: 365, divisions: 4,
            activeColor: kCyan, inactiveColor: Colors.white10,
            onChanged: (val) => setState(() => _logRetentionDays = val),
          ),
          Text("Passé ce délai, les logs sont purgés automatiquement (Conformité RGPD).", style: TextStyle(color: Colors.blueGrey[500], fontSize: 10)),
        ]),
        const SizedBox(height: 32),

        // --- SECTION 3 : INTÉGRATIONS & ALERTING ---
        _buildSectionHeader(CupertinoIcons.bell_fill, "Webhooks & Alerting"),
        _buildSettingsCard([
          _buildSwitchRow("Alerte Slack / Microsoft Teams", "Envoi des alertes CRITICAL sur le canal du SOC.", _enableSlackWebhooks, (v) => setState(() => _enableSlackWebhooks = v)),
          if (_enableSlackWebhooks) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFF070B14), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
              child: TextField(
                style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(hintText: "https://hooks.slack.com/services/...", hintStyle: TextStyle(color: Colors.white30), border: InputBorder.none),
              ),
            )
          ],
          const Divider(color: Colors.white12, height: 32),
          _buildSwitchRow("Syslog Forwarding (SIEM Externe)", "Transfère les logs vers Splunk ou Datadog (UDP 514).", _enableSyslogForwarding, (v) => setState(() => _enableSyslogForwarding = v)),
        ]),
        const SizedBox(height: 32),

        // --- SECTION 4 : MAINTENANCE ---
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2A55).withValues(alpha: 0.1), foregroundColor: const Color(0xFFFF2A55), side: const BorderSide(color: Color(0xFFFF2A55)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(CupertinoIcons.restart, size: 18),
            label: const Text("REDÉMARRER LE CONTRÔLEUR DARCK PULS", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: kCyan, size: 18),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: Colors.blueGrey[300], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
            ],
          ),
        ),
        CupertinoSwitch(value: value, activeColor: kCyan, onChanged: onChanged),
      ],
    );
  }

  Widget _buildActionRow(String title, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Text(value, style: TextStyle(color: kCyan, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.blueGrey, size: 14),
            ],
          ),
        )
      ],
    );
  }
}