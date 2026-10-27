import 'package:flutter/foundation.dart';
import 'dart:io';

class DesktopWifiNetwork {
  final String ssid;
  final String bssid;

  /// Signal en dBm. Peut être null si la valeur n'a pas pu être mesurée.
  final int? rssi;

  /// Fréquence en MHz. Peut être null si elle n'a pas pu être déterminée.
  final int? frequency;

  final String? channel;

  const DesktopWifiNetwork({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.frequency,
    this.channel,
  });

  bool get hasMeasuredSignal => rssi != null;
}

class DesktopWifiScanner {
  static Future<List<DesktopWifiNetwork>> scan() async {
    List<DesktopWifiNetwork> networks;

    try {
      if (Platform.isWindows) {
        networks = await _scanWindows();
      } else if (Platform.isLinux) {
        networks = await _scanLinux();
      } else if (Platform.isMacOS) {
        networks = await _scanMacOS();
      } else {
        networks = const <DesktopWifiNetwork>[];
      }
    } catch (e) {
      debugPrint('Erreur du scan Wi-Fi : $e');
      networks = const <DesktopWifiNetwork>[];
    }

    final sorted = List<DesktopWifiNetwork>.from(networks);

    sorted.sort((a, b) {
      final signalA = a.rssi ?? -999;
      final signalB = b.rssi ?? -999;
      return signalB.compareTo(signalA);
    });

    return sorted;
  }

  // ==========================================================
  // WINDOWS : netsh wlan show networks mode=bssid
  // ==========================================================

  static Future<List<DesktopWifiNetwork>> _scanWindows() async {
    final result = await Process.run(
      'netsh',
      ['wlan', 'show', 'networks', 'mode=bssid'],
      stdoutEncoding: const SystemEncoding(),
    );

    if (result.exitCode != 0) {
      throw Exception(
        'netsh a échoué (code ${result.exitCode}) : '
            '${result.stderr}',
      );
    }

    final output = result.stdout.toString();
    final networks = <DesktopWifiNetwork>[];

    String? currentSsid;
    int? currentSignalPercent;
    String? currentChannel;
    String? currentBssid;

    void addCurrentNetwork() {
      if (currentBssid == null) return;

      networks.add(
        DesktopWifiNetwork(
          ssid: currentSsid ?? '',
          bssid: currentBssid!,
          rssi: currentSignalPercent == null
              ? null
              : _windowsPercentToDbm(currentSignalPercent!),
          frequency: currentChannel == null
              ? null
              : _channelToFrequencyMHz(currentChannel!),
          channel: currentChannel,
        ),
      );

      currentBssid = null;
      currentSignalPercent = null;
      currentChannel = null;
    }

    for (final rawLine in output.splitLines()) {
      final line = rawLine.trim();

      if (line.isEmpty) continue;

      final separatorIndex = line.indexOf(':');
      if (separatorIndex < 0) continue;

      final key = line
          .substring(0, separatorIndex)
          .trim()
          .toLowerCase();
      final value = line.substring(separatorIndex + 1).trim();

      if (key.startsWith('ssid')) {
        // Un nouveau SSID commence un nouveau bloc réseau.
        addCurrentNetwork();
        currentSsid = value;
        currentSignalPercent = null;
        currentChannel = null;
        currentBssid = null;
      } else if (key.startsWith('bssid')) {
        // Plusieurs BSSID peuvent appartenir au même SSID.
        addCurrentNetwork();
        currentBssid = value;
      } else if (key.startsWith('signal')) {
        final percent = RegExp(r'(\d{1,3})').firstMatch(value)?.group(1);
        currentSignalPercent =
        percent == null ? null : int.tryParse(percent);
      } else if (key.startsWith('canal') || key.startsWith('channel')) {
        currentChannel = value;
      }
    }

    addCurrentNetwork();

    return networks;
  }

  /// Conversion approximative du pourcentage Windows vers dBm.
  ///
  /// Windows affiche une qualité relative, pas directement un RSSI.
  /// Cette conversion est une approximation courante, pas une mesure
  /// physique exacte.
  static int _windowsPercentToDbm(int percent) {
    final bounded = percent.clamp(0, 100);
    return (bounded / 2).round() - 100;
  }

  /// Conversion indicative canal Wi-Fi vers fréquence centrale.
  static int? _channelToFrequencyMHz(String channelText) {
    final channel = int.tryParse(channelText);

    if (channel == null) return null;

    if (channel >= 1 && channel <= 13) {
      return 2407 + channel * 5;
    }

    if (channel == 14) {
      return 2484;
    }

    if (channel >= 32 && channel <= 177) {
      return 5000 + channel * 5;
    }

    return null;
  }

  // ==========================================================
  // LINUX : nmcli
  // ==========================================================

  static Future<List<DesktopWifiNetwork>> _scanLinux() async {
    // Le séparateur explicite évite les erreurs lorsque le SSID
    // contient lui-même le caractère ':'.
    const separator = '|';

    final result = await Process.run(
      'nmcli',
      [
        '-t',
        '--separator',
        separator,
        '-f',
        'SSID,BSSID,SIGNAL,FREQ,CHAN',
        'device',
        'wifi',
        'list',
      ],
    );

    if (result.exitCode != 0) {
      throw Exception(
        'nmcli a échoué (code ${result.exitCode}) : '
            '${result.stderr}',
      );
    }

    final output = result.stdout.toString();
    final networks = <DesktopWifiNetwork>[];

    for (final rawLine in output.split('\n')) {
      final line = rawLine.trim();

      if (line.isEmpty) continue;

      final parts = line.split(separator);

      if (parts.length < 5) continue;

      final ssid = parts[0];
      final bssid = parts[1];
      final signalPercent = int.tryParse(parts[2]);
      final frequency = int.tryParse(parts[3]);
      final channel = parts[4];

      // Ignore les entrées sans adresse MAC valide.
      if (!_isValidMacAddress(bssid)) continue;

      networks.add(
        DesktopWifiNetwork(
          ssid: ssid,
          bssid: bssid,
          rssi: signalPercent == null
              ? null
              : _linuxPercentToDbm(signalPercent),
          frequency: frequency,
          channel: channel.isEmpty ? null : channel,
        ),
      );
    }

    return networks;
  }

  /// Conversion approximative du pourcentage NetworkManager vers dBm.
  static int _linuxPercentToDbm(int percent) {
    final bounded = percent.clamp(0, 100);
    return (bounded / 2).round() - 100;
  }

  static bool _isValidMacAddress(String value) {
    return RegExp(
      r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$',
    ).hasMatch(value);
  }

  // ==========================================================
  // MACOS : outil airport
  // ==========================================================

  static Future<List<DesktopWifiNetwork>> _scanMacOS() async {
    // Cet outil privé a été retiré de certaines versions récentes
    // de macOS. Son absence doit être signalée, pas masquée.
    const airportPath =
        '/System/Library/PrivateFrameworks/Apple80211.framework/'
        'Versions/Current/Resources/airport';

    final executable = File(airportPath);

    if (!await executable.exists()) {
      throw Exception(
        'L’outil airport n’est pas disponible sur cette version '
            'de macOS.',
      );
    }

    final result = await Process.run(airportPath, ['-s']);

    if (result.exitCode != 0) {
      throw Exception(
        'airport a échoué (code ${result.exitCode}) : '
            '${result.stderr}',
      );
    }

    final output = result.stdout.toString();
    final lines = output
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.length <= 1) {
      return const <DesktopWifiNetwork>[];
    }

    final networks = <DesktopWifiNetwork>[];

    // La première ligne est l'en-tête.
    for (final line in lines.sublist(1)) {
      final parts = line.trim().split(RegExp(r'\s{2,}'));

      if (parts.length < 3) continue;

      final ssid = parts[0];
      final bssid = parts[1];
      final rssi = int.tryParse(parts[2]);

      if (!_isValidMacAddress(bssid)) continue;

      networks.add(
        DesktopWifiNetwork(
          ssid: ssid,
          bssid: bssid,
          rssi: rssi,
          frequency: null,
        ),
      );
    }

    return networks;
  }
}

extension _StringSplitLines on String {
  List<String> splitLines() {
    return split(RegExp(r'\r?\n'));
  }
}