// ============================================================
// CHAT BLOC
// ============================================================
// Manages a single order's chat thread at a time.
// Screens open a thread with ChatEventOpen and close it
// with ChatEventClose (typically in dispose).
// ============================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/models/chat_message_model.dart';
import 'package:forfood/service/chat/chat_event.dart';
import 'package:forfood/service/chat/chat_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final FirestoreProvider _firestoreProvider;
  StreamSubscription<List<ChatMessageModel>>? _subscription;

  ChatBloc(FirestoreProvider firestoreProvider)
      : _firestoreProvider = firestoreProvider,
        super(const ChatStateIdle()) {
    on<ChatEventOpen>(_onOpen);
    on<ChatEventClose>(_onClose);
    on<ChatEventSend>(_onSend);
    on<ChatEventMessagesUpdated>(_onMessagesUpdated);
    on<ChatEventStreamError>(_onStreamError);
  }

  // ============================================================
  // OPEN — start streaming this order's messages
  // ============================================================
  Future<void> _onOpen(
    ChatEventOpen event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatStateLoading());

    await _subscription?.cancel();

    _subscription = _firestoreProvider
        .streamOrderMessages(event.orderId)
        .listen(
      (messages) {
        if (!isClosed) {
          add(ChatEventMessagesUpdated(messages: messages));
        }
      },
      onError: (error) {
        if (!isClosed) {
          add(ChatEventStreamError(message: error.toString()));
        }
      },
    );
  }

  // ============================================================
  // CLOSE — stop streaming
  // ============================================================
  Future<void> _onClose(
    ChatEventClose event,
    Emitter<ChatState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
    emit(const ChatStateIdle());
  }

  // ============================================================
  // SEND — write a new message to Firestore
  // ============================================================
  Future<void> _onSend(
    ChatEventSend event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _firestoreProvider.sendOrderMessage(event.message);
      // No emit — the stream will push the new message back
      // via ChatEventMessagesUpdated.
    } on FirestoreOperationException catch (e) {
      emit(ChatStateError(message: e.message));
    } catch (e) {
      emit(ChatStateError(message: 'Failed to send: $e'));
    }
  }

  // ============================================================
  // INTERNAL STREAM HANDLERS
  // ============================================================
  void _onMessagesUpdated(
    ChatEventMessagesUpdated event,
    Emitter<ChatState> emit,
  ) {
    emit(ChatStateLoaded(messages: event.messages));
  }

  void _onStreamError(
    ChatEventStreamError event,
    Emitter<ChatState> emit,
  ) {
    emit(ChatStateError(message: event.message));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}