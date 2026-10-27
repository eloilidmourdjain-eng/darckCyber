class HoneypotAlert {
  final String id;
  final String triggerType;
  final String ipAddress;
  final String deviceFingerprint;
  final String userId;
  final DateTime timestamp;

  // Informations complémentaires facultatives.
  final int? targetPort;
  final String? protocol;
  final String? severity;
  final int? attemptCount;
  final String? status;

  const HoneypotAlert({
    required this.id,
    required this.triggerType,
    required this.ipAddress,
    required this.deviceFingerprint,
    required this.userId,
    required this.timestamp,
    this.targetPort,
    this.protocol,
    this.severity,
    this.attemptCount,
    this.status,
  });

  // ==========================================================
  // LECTURE DES CHAMPS
  // ==========================================================

  static Object? _firstValue(
      Map<String, dynamic> json,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = json[key];

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  static String? _optionalText(
      Map<String, dynamic> json,
      List<String> keys,
      String fieldName,
      ) {
    final value = _firstValue(json, keys);

    if (value == null) return null;

    if (value is! String) {
      throw FormatException(
        'Champ "$fieldName" invalide : une chaîne est attendue.',
      );
    }

    final text = value.trim();

    return text.isEmpty ? null : text;
  }

  static String _requiredText(
      Map<String, dynamic> json,
      List<String> keys,
      String fieldName,
      ) {
    final value = _optionalText(json, keys, fieldName);

    if (value == null) {
      throw FormatException(
        'Champ obligatoire "$fieldName" absent ou vide.',
      );
    }

    return value;
  }

  static int? _optionalInteger(
      Map<String, dynamic> json,
      List<String> keys,
      String fieldName, {
        required int minimum,
        int? maximum,
      }) {
    final value = _firstValue(json, keys);

    if (value == null) return null;

    int? number;

    if (value is int) {
      number = value;
    } else if (value is String) {
      number = int.tryParse(value.trim());
    }

    if (number == null) {
      throw FormatException(
        'Champ "$fieldName" invalide : un entier est attendu.',
      );
    }

    if (number < minimum ||
        (maximum != null && number > maximum)) {
      throw FormatException(
        'Champ "$fieldName" hors limites.',
      );
    }

    return number;
  }

  static DateTime _readTimestamp(Map<String, dynamic> json) {
    final raw = _requiredText(
      json,
      ['timestamp'],
      'timestamp',
    );

    // Contrat accepté :
    // 2026-10-27T10:00:00Z
    // 2026-10-27T10:00:00.123Z
    // 2026-10-27T10:00:00+03:00
    final pattern = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})'
      r'T(\d{2}):(\d{2}):(\d{2})'
      r'(?:\.(\d{1,6}))?'
      r'(Z|([+-])(\d{2}):(\d{2}))$',
    );

    final match = pattern.firstMatch(raw);

    if (match == null) {
      throw const FormatException(
        'Timestamp invalide. Format attendu : '
            '2026-10-27T10:00:00Z ou '
            '2026-10-27T10:00:00+03:00.',
      );
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    final second = int.parse(match.group(6)!);

    if (month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        hour > 23 ||
        minute > 59 ||
        second > 59) {
      throw const FormatException(
        'Timestamp invalide : date ou heure hors limites.',
      );
    }

    // Vérifie également les dates impossibles,
    // par exemple le 31 février.
    final calendarDate = DateTime.utc(year, month, day);

    if (calendarDate.year != year ||
        calendarDate.month != month ||
        calendarDate.day != day) {
      throw const FormatException(
        'Timestamp invalide : date inexistante.',
      );
    }

    if (match.group(8) != 'Z') {
      final offsetHour = int.parse(match.group(10)!);
      final offsetMinute = int.parse(match.group(11)!);

      if (offsetHour > 14 ||
          offsetMinute > 59 ||
          (offsetHour == 14 && offsetMinute != 0)) {
        throw const FormatException(
          'Timestamp invalide : décalage horaire non accepté.',
        );
      }
    }

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      throw const FormatException(
        'Timestamp non interprétable.',
      );
    }

    return parsed.toUtc();
  }

  // ==========================================================
  // CONVERSION JSON → MODÈLE
  // ==========================================================

  factory HoneypotAlert.fromJson(Map<String, dynamic> json) {
    return HoneypotAlert(
      id: _requiredText(
        json,
        ['id'],
        'id',
      ),
      triggerType: _requiredText(
        json,
        ['triggerType', 'trigger_type'],
        'triggerType',
      ),
      ipAddress: _requiredText(
        json,
        ['ipAddress', 'ip_address', 'source_ip'],
        'ipAddress',
      ),
      deviceFingerprint: _optionalText(
        json,
        ['deviceFingerprint', 'device_fingerprint'],
        'deviceFingerprint',
      ) ??
          'Non renseignée',
      userId: _optionalText(
        json,
        ['user_id', 'userId'],
        'userId',
      ) ??
          'anonymous',
      timestamp: _readTimestamp(json),
      targetPort: _optionalInteger(
        json,
        ['targetPort', 'target_port', 'destination_port'],
        'targetPort',
        minimum: 1,
        maximum: 65535,
      ),
      protocol: _optionalText(
        json,
        ['protocol'],
        'protocol',
      ),
      severity: _optionalText(
        json,
        ['severity'],
        'severity',
      ),
      attemptCount: _optionalInteger(
        json,
        ['attemptCount', 'attempt_count'],
        'attemptCount',
        minimum: 0,
      ),
      status: _optionalText(
        json,
        ['status'],
        'status',
      ),
    );
  }

  // ==========================================================
  // CONVERSION MODÈLE → JSON
  // ==========================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'triggerType': triggerType,
      'ipAddress': ipAddress,
      'deviceFingerprint': deviceFingerprint,
      'user_id': userId,
      'timestamp': timestamp.toUtc().toIso8601String(),
      if (targetPort != null) 'target_port': targetPort,
      if (protocol != null) 'protocol': protocol,
      if (severity != null) 'severity': severity,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (status != null) 'status': status,
    };
  }

  // ==========================================================
  // UTILITAIRES
  // ==========================================================

  DateTime get localTimestamp => timestamp.toLocal();

  @override
  String toString() {
    // Ne journalise pas l'ensemble du contenu de l'événement.
    return 'HoneypotAlert('
        'id: $id, '
        'type: $triggerType, '
        'port: $targetPort, '
        'timestamp: ${timestamp.toUtc().toIso8601String()}'
        ')';
  }
}