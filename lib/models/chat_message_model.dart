// ============================================================
// CHAT MESSAGE MODEL
// ============================================================
// Represents a single message in an order's chat thread.
// Maps to Firestore at: /orders/{orderId}/messages/{messageId}
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatSender {
  user,
  restaurant;

  String get name => toString().split('.').last;

  static ChatSender fromString(String value) {
    return ChatSender.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ChatSender.user,
    );
  }
}

class ChatMessageModel {
  final String id;
  final String orderId;

  /// Firebase Auth UID of the sender.
  final String senderId;

  /// Who sent the message — user or restaurant.
  final ChatSender sender;

  /// Message body.
  final String text;

  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  // ============================================================
  // FIRESTORE CONVERSION
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'senderId': senderId,
      'sender': sender.name,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChatMessageModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final orderId = map['orderId'] as String?;
    final senderId = map['senderId'] as String?;
    final senderString = map['sender'] as String?;
    final text = map['text'] as String?;
    final createdAt = map['createdAt'] as Timestamp?;

    if (orderId == null) {
      throw StateError('ChatMessageModel.fromMap: "orderId" is required');
    }
    if (senderId == null) {
      throw StateError('ChatMessageModel.fromMap: "senderId" is required');
    }
    if (senderString == null) {
      throw StateError('ChatMessageModel.fromMap: "sender" is required');
    }
    if (text == null) {
      throw StateError('ChatMessageModel.fromMap: "text" is required');
    }
    if (createdAt == null) {
      throw StateError('ChatMessageModel.fromMap: "createdAt" is required');
    }

    return ChatMessageModel(
      id: id,
      orderId: orderId,
      senderId: senderId,
      sender: ChatSender.fromString(senderString),
      text: text,
      createdAt: createdAt.toDate(),
    );
  }

  @override
  String toString() {
    return 'ChatMessageModel(id: $id, orderId: $orderId, sender: $sender, text: $text)';
  }
}