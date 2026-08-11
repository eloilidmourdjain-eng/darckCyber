class HoneypotAlert {
  final String id;
  final String triggerType; // ex: "Accès non autorisé"
  final String ipAddress;
  final String deviceFingerprint;
  final String userId;
  final DateTime timestamp;

  HoneypotAlert({
    required this.id,
    required this.triggerType,
    required this.ipAddress,
    required this.deviceFingerprint,
    required this.userId,
    required this.timestamp,
  });
  factory HoneypotAlert.fromJson(Map<String, dynamic> json){
    return HoneypotAlert(
        id: json['id'] ??'',
        triggerType: json['triggerType'],
        ipAddress: json['ipAddress'],
        deviceFingerprint: json['deviceFingerprint'],
        userId: json['user_id']??'anonymous',
        timestamp: DateTime.parse(json['timestamp']?? DateTime.now().toIso8601String()),
    );
  }
}