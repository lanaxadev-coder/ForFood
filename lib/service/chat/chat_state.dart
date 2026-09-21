// ============================================================
// CHAT STATES
// ============================================================

import 'package:forfood/models/chat_message_model.dart';

abstract class ChatState {
  const ChatState();
}

/// No thread opened yet.
class ChatStateIdle extends ChatState {
  const ChatStateIdle();
}

/// Loading a thread's messages for the first time.
class ChatStateLoading extends ChatState {
  const ChatStateLoading();
}

/// Messages loaded (may be empty if no messages yet).
class ChatStateLoaded extends ChatState {
  final List<ChatMessageModel> messages;

  const ChatStateLoaded({required this.messages});

  bool get isEmpty => messages.isEmpty;
  bool get isNotEmpty => messages.isNotEmpty;
}

/// Something went wrong.
class ChatStateError extends ChatState {
  final String message;

  const ChatStateError({required this.message});
}