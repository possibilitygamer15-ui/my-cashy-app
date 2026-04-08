import 'package:cloud_firestore/cloud_firestore.dart';

class SupportChatMessage {
  const SupportChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String text;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  factory SupportChatMessage.fromMap(String id, Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return SupportChatMessage(
      id: id,
      role: (map['role'] ?? 'assistant') as String,
      text: (map['text'] ?? '') as String,
      createdAt: createdAt,
    );
  }
}
