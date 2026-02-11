import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final bool isAdmin;
  final String text;
  final Timestamp createdAt;
  final bool read;

  Message({
    required this.id,
    required this.isAdmin,
    required this.text,
    required this.createdAt,
    required this.read,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      isAdmin: data["IsAdmin"] ?? false,
      text: data["Text"] ?? "",
      createdAt: data["CreatedAt"] ?? Timestamp.now(),
      read: data["Read"] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "ID": id,
      "IsAdmin": isAdmin,
      "Text": text,
      "CreatedAt": createdAt,
      "Read": read,
    };
  }
}
