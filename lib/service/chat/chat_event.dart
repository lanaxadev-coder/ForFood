// ============================================================
// CHAT EVENTS
// ============================================================

import 'package:forfood/models/chat_message_model.dart';

abstract class ChatEvent {
  const ChatEvent();
}

/// Start listening to a specific order's chat thread.
class ChatEventOpen extends ChatEvent {
  final String orderId;

  const ChatEventOpen({required this.orderId});
}

/// Stop listening (screen disposed).
class ChatEventClose extends ChatEvent {
  const ChatEventClose();
}

/// Send a new message.
class ChatEventSend extends ChatEvent {
  final ChatMessageModel message;

  const ChatEventSend({required this.message});
}

// ── Internal events dispatched from stream callbacks ──

class ChatEventMessagesUpdated extends ChatEvent {
  final List<ChatMessageModel> messages;

  const ChatEventMessagesUpdated({required this.messages});
}

class ChatEventStreamError extends ChatEvent {
  final String message;

  const ChatEventStreamError({required this.message});
}