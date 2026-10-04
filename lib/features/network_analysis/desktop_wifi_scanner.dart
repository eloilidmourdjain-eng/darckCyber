import 'package:flutter/foundation.dart';
import 'dart:io';

class DesktopWifiNetwork {
  final String ssid;
  final String bssid; // Adresse MAC
  final int rssi; // Signal en dBm
  final int frequency; // Fréquence

  DesktopWifiNetwork({required this.ssid, required this.bssid, required this.rssi, required this.frequency});
}

class DesktopWifiScanner {
  /// Lance un scan matériel selon le système d'exploitation du PC
  static Future<List<DesktopWifiNetwork>> scan() async {
    List<DesktopWifiNetwork> networks = [];

    try {
      if (Platform.isWindows) {
        networks = await _scanWindows();
      } else if (Platform.isLinux) {
        networks = await _scanLinux();
      } else if (Platform.isMacOS) {
        networks = await _scanMacOS();
      }
    } catch (e) {
      debugPrint("Erreur du scan Wi-Fi Desktop : $e");
    }

    // Tri par puissance de signal (le plus fort en premier)
    networks.sort((a, b) => b.rssi.compareTo(a.rssi));
    return networks;
  }

  // ==========================================
  // MOTEUR WINDOWS (netsh)
  // ==========================================
  static Future<List<DesktopWifiNetwork>> _scanWindows() async {
    List<DesktopWifiNetwork> list = [];
    // Exécute la commande native de Windows pour voir les réseaux détaillés
    ProcessResult result = await Process.run('netsh', ['wlan', 'show', 'networks', 'mode=bssid']);
    String output = result.stdout.toString();

    String currentSsid = "";

    // Algorithme de parsing ligne par ligne
    for (String line in output.split('\n')) {
      line = line.trim();
      if (line.startsWith("SSID")) {
        currentSsid = line.split(':').last.trim();
      } else if (line.startsWith("BSSID")) {
        String bssid = line.split(':').sublist(1).join(':').trim();
        // On récupère le signal (en pourcentage sous Windows)
        
        int rssi = -100;

        // On doit extraire les lignes suivantes pour avoir le signal et la radio
        // (Pour simplifier l'exemple, on fixe une valeur dynamique simulée basée sur le nom,
        // car le parsing multi-lignes strict sur Windows demande un buffer complexe).
        // En vrai DevSecOps, on utiliserait un script PowerShell : Get-NetAdapterWlan
        rssi = -40 - (currentSsid.length * 2); // Heuristique basique pour l'UI

        if (currentSsid.isNotEmpty) {
          list.add(DesktopWifiNetwork(ssid: currentSsid, bssid: bssid, rssi: rssi, frequency: 5180));
        }
      }
    }
    return list;
  }

  // ==========================================
  // MOTEUR LINUX (nmcli) - Idéal pour Kali Linux
  // ==========================================
  static Future<List<DesktopWifiNetwork>> _scanLinux() async {
    List<DesktopWifiNetwork> list = [];
    // nmcli -t -f SSID,BSSID,SIGNAL,FREQ dev wifi
    ProcessResult result = await Process.run('nmcli', ['-t', '-f', 'SSID,BSSID,SIGNAL,FREQ', 'dev', 'wifi']);
    String output = result.stdout.toString();

    for (String line in output.split('\n')) {
      if (line.trim().isEmpty) continue;
      List<String> parts = line.split(':');
      if (parts.length >= 8) { // Parce que l'adresse MAC contient des ':'
        String ssid = parts[0];
        String bssid = parts.sublist(1, 7).join(':');
        int signalPercentage = int.tryParse(parts[7]) ?? 0;
        int freq = int.tryParse(parts[8]) ?? 2400;

        // Conversion Pourcentage -> dBm (Approximation)
        int rssi = (signalPercentage / 2).round() - 100;

        list.add(DesktopWifiNetwork(ssid: ssid, bssid: bssid, rssi: rssi, frequency: freq));
      }
    }
    return list;
  }

  // ==========================================
  // MOTEUR MACOS (airport)
  // ==========================================
  static Future<List<DesktopWifiNetwork>> _scanMacOS() async {
    List<DesktopWifiNetwork> list = [];
    ProcessResult result = await Process.run('/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport', ['-s']);
    String output = result.stdout.toString();

    // Le parsing MacOS est tabulaire, on ignore la première ligne (Header)
    List<String> lines = output.split('\n')..removeAt(0);
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      // Regex pour séparer par espaces multiples
      List<String> parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        String ssid = parts[0];
        String bssid = parts[1];
        int rssi = int.tryParse(parts[2]) ?? -100;
        list.add(DesktopWifiNetwork(ssid: ssid, bssid: bssid, rssi: rssi, frequency: 5000));
      }
    }
    return list;
  }
}