import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalLog {
  final String id;
  final DateTime timestamp;
  final String category;
  final String severity;
  final String message;
  final String source;
  final String? integrityHash;

  const GlobalLog({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.severity,
    required this.message,
    required this.source,
    this.integrityHash,
  });

  String get formattedTime {
    final local = timestamp.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(local.hour)}:${two(local.minute)}:'
        '${two(local.second)}';
  }
}

class LogCenterScreen extends StatefulWidget {
  const LogCenterScreen({super.key});

  @override
  State<LogCenterScreen> createState() => _LogCenterScreenState();
}

class _LogCenterScreenState extends State<LogCenterScreen> {
  static const Color _backgroundColor = Color(0xFF070B14);
  static const Color _cardColor = Color(0xFF131C2D);
  static const Color _accentColor = Color(0xFF00E5FF);

  final TextEditingController _searchController =
  TextEditingController();

  final List<GlobalLog> _masterLogs = [];
  List<GlobalLog> _filteredLogs = [];

  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadDemonstrationLogs();
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // DONNÉES DE DÉMONSTRATION
  // ==========================================================

  void _loadDemonstrationLogs() {
    final now = DateTime.now();

    _masterLogs.addAll([
      GlobalLog(
        id: 'LOG-001',
        timestamp: now.subtract(const Duration(minutes: 2)),
        category: 'SECURITY',
        severity: 'CRITICAL',
        message:
        'Événement de démonstration : tentatives répétées '
            'sur le port SSH depuis 192.168.1.50.',
        source: 'Démonstration locale',
      ),
      GlobalLog(
        id: 'LOG-002',
        timestamp: now.subtract(const Duration(minutes: 5)),
        category: 'NETWORK',
        severity: 'WARNING',
        message:
        'Événement de démonstration : latence élevée '
            'simulée sur une liaison WAN.',
        source: 'Démonstration locale',
      ),
      GlobalLog(
        id: 'LOG-003',
        timestamp: now.subtract(const Duration(minutes: 12)),
        category: 'SYSTEM',
        severity: 'INFO',
        message:
        'Événement de démonstration : sauvegarde terminée.',
        source: 'Démonstration locale',
      ),
      GlobalLog(
        id: 'LOG-004',
        timestamp: now.subtract(const Duration(hours: 1)),
        category: 'SECURITY',
        severity: 'INFO',
        message:
        'Événement de démonstration : connexion administrateur '
            'avec authentification multifacteur.',
        source: 'Démonstration locale',
      ),
      GlobalLog(
        id: 'LOG-005',
        timestamp: now.subtract(const Duration(hours: 2)),
        category: 'SYSTEM',
        severity: 'CRITICAL',
        message:
        'Événement de démonstration : défaillance matérielle '
            'simulée.',
        source: 'Démonstration locale',
      ),
    ]);
  }

  // ==========================================================
  // FILTRAGE
  // ==========================================================

  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();

    final result = _masterLogs.where((log) {
      final matchesQuery = query.isEmpty ||
          log.id.toLowerCase().contains(query) ||
          log.message.toLowerCase().contains(query) ||
          log.category.toLowerCase().contains(query) ||
          log.severity.toLowerCase().contains(query);

      final matchesCategory = _selectedCategory == 'ALL' ||
          log.category == _selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();

    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      _filteredLogs = result;
    });
  }

  // ==========================================================
  // EXPORT CSV RÉEL
  // ==========================================================

  String _csvCell(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }

  String _buildCsv() {
    final rows = <String>[
      'id,horodatage_utc,categorie,gravite,source,message,empreinte',
    ];

    for (final log in _filteredLogs) {
      rows.add([
        log.id,
        log.timestamp.toUtc().toIso8601String(),
        log.category,
        log.severity,
        log.source,
        log.message,
        log.integrityHash ?? '',
      ].map(_csvCell).join(','));
    }

    return '${rows.join('\r\n')}\r\n';
  }

  Future<void> _exportCsv() async {
    if (_isExporting) return;

    if (_filteredLogs.isEmpty) {
      _notify('Aucun journal filtré à exporter.');
      return;
    }

    final initialPath = [
      Directory.systemTemp.path,
      'dark_puls_logs_'
          '${DateTime.now().millisecondsSinceEpoch}.csv',
    ].join(Platform.pathSeparator);

    final pathController = TextEditingController(text: initialPath);

    final selectedPath = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enregistrer le fichier CSV'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: pathController,
            decoration: const InputDecoration(
              labelText: 'Chemin complet du fichier',
              helperText:
              'Le dossier doit exister et être accessible en écriture.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, pathController.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    pathController.dispose();

    if (selectedPath == null || selectedPath.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final file = File(selectedPath);

      if (await file.exists()) {
        final overwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Fichier existant'),
            content: const Text(
              'Un fichier existe déjà à cet emplacement. '
                  'Le remplacer ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remplacer'),
              ),
            ],
          ),
        );

        if (overwrite != true || !mounted) return;
      }

      // \uFEFF aide Excel à reconnaître l'encodage UTF-8.
      await file.writeAsString(
        '\uFEFF${_buildCsv()}',
        encoding: utf8,
        flush: true,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export terminé'),
          content: SelectableText(
            'Fichier enregistré :\n${file.absolute.path}',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: file.absolute.path),
                );
              },
              child: const Text('Copier le chemin'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } on FileSystemException catch (e) {
      _notify(
        'Échec de l’écriture du fichier : ${e.message}. '
            'Vérifie le dossier et les permissions.',
      );
    } catch (e) {
      _notify('Échec de l’export : $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
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

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFFF2A55);
      case 'WARNING':
        return Colors.orangeAccent;
      case 'INFO':
      default:
        return _accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CENTRE DE CONSULTATION DES JOURNAUX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Consultation et filtrage des journaux '
                        'de démonstration.',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed:
                _isExporting ? null : () => _exportCsv(),
                icon: _isExporting
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(CupertinoIcons.tray_arrow_down,
                    size: 16),
                label: Text(
                  _isExporting
                      ? 'Export en cours...'
                      : 'Exporter CSV',
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _cardColor,
                    prefixIcon: const Icon(
                      CupertinoIcons.search,
                      color: Colors.blueGrey,
                      size: 18,
                    ),
                    hintText:
                    'Rechercher un mot-clé ou un identifiant...',
                    hintStyle:
                    const TextStyle(color: Colors.white30),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              _buildCategoryDropdown(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '${_filteredLogs.length} journal(aux) affiché(s) '
                'sur ${_masterLogs.length}.',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ),

        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _filteredLogs.isEmpty
                ? const Center(
              child: Text(
                'Aucun journal ne correspond aux filtres.',
                style: TextStyle(color: Colors.white54),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredLogs.length,
              separatorBuilder: (context, index) =>
              const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                final log = _filteredLogs[index];
                final severityColor =
                _severityColor(log.severity);

                return Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[${log.formattedTime}]',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.blueGrey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: Text(
                          log.category,
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Container(
                          padding: const EdgeInsets
                              .symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: severityColor
                                .withValues(alpha: 0.1),
                            borderRadius:
                            BorderRadius.circular(4),
                            border: Border.all(
                              color: severityColor
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            log.severity,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: severityColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Source : ${log.source}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Tooltip(
                        message: log.integrityHash == null
                            ? 'Aucune empreinte fournie '
                            'pour cette entrée.'
                            : 'Empreinte fournie : '
                            '${log.integrityHash}',
                        child: Icon(
                          log.integrityHash == null
                              ? CupertinoIcons.info_circle
                              : CupertinoIcons.lock_shield,
                          color: log.integrityHash == null
                              ? Colors.white24
                              : Colors.greenAccent,
                          size: 16,
                        ),
                      ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: _cardColor,
          value: _selectedCategory,
          icon: const Icon(
            CupertinoIcons.chevron_down,
            color: Colors.blueGrey,
            size: 14,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          items: const [
            'ALL',
            'SECURITY',
            'SYSTEM',
            'NETWORK',
          ]
              .map(
                (value) => DropdownMenuItem(
              value: value,
              child: Text(value),
            ),
          )
              .toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedCategory = value;
            });

            _applyFilters();
          },
        ),
      ),
    );
  }
}