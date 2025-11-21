import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumLog {
  final String telId;
  final DateTime timestamp;
  final String detail; // "契約" or "解約"

  PremiumLog({
    required this.telId,
    required this.timestamp,
    required this.detail,
  });

  factory PremiumLog.fromMap(Map<String, dynamic> map) {
    return PremiumLog(
      telId: map['ID'],
      timestamp: (map['Timestamp'] as Timestamp).toDate(),
      detail: map['Detail'],
    );
  }
}
