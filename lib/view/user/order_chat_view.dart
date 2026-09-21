// ============================================================
// ORDER CHAT VIEW — user ↔ restaurant messaging per order
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/models/chat_message_model.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/chat/chat_bloc.dart';
import 'package:forfood/service/chat/chat_event.dart';
import 'package:forfood/service/chat/chat_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/utilities/haptic_feedback.dart';

class OrderChatView extends StatelessWidget {
  final OrderModel order;

  const OrderChatView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ChatBloc(ctx.read<FirestoreProvider>())
        ..add(ChatEventOpen(orderId: order.id)),
      child: _OrderChatBody(order: order),
    );
  }
}

// ============================================================
// BODY
// ============================================================
class _OrderChatBody extends StatefulWidget {
  final OrderModel order;

  const _OrderChatBody({required this.order});

  @override
  State<_OrderChatBody> createState() => _OrderChatBodyState();
}

class _OrderChatBodyState extends State<_OrderChatBody> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() {
    // ✅ Block sends on closed orders
    if (widget.order.status.isTerminal) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthStateLoggedIn) return;

    HapticFeedbackUtil.light();

    context.read<ChatBloc>().add(
          ChatEventSend(
            message: ChatMessageModel(
              id: '',
              orderId: widget.order.id,
              senderId: authState.user.id,
              sender: ChatSender.user,
              text: text,
              createdAt: DateTime.now(),
            ),
          ),
        );

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isClosed = widget.order.status.isTerminal;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: screenWidth,
        height: screenHeight,
        color: const Color(0xFFF5CB58),
        child: Stack(
          children: [
            // White bottom section
            Positioned(
              left: 0,
              top: 163 * heightScale,
              child: Container(
                width: screenWidth,
                height: screenHeight - (163 * heightScale),
                clipBehavior: Clip.antiAlias,
                decoration: const ShapeDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                ),
              ),
            ),

            // Back button
            Positioned(
              left: 35 * widthScale,
              top: 84 * heightScale,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Image.asset(
                  'assets/icons/BackiconArrow.png',
                  width: 20 * widthScale,
                  height: 20 * heightScale,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Title + subtitle
            Positioned(
              left: 70 * widthScale,
              top: 70 * heightScale,
              right: 20 * widthScale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.order.restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColor.textDark,
                      fontSize: 22 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2 * heightScale),
                  Text(
                    'Order #${_shortId(widget.order.id)}',
                    style: TextStyle(
                      color: AppColor.orange,
                      fontSize: 13 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Messages + input
            Positioned(
              left: 0,
              right: 0,
              top: 175 * heightScale,
              bottom: 0,
              child: Column(
                children: [
                  // ───── Messages list ─────
                  Expanded(
                    child: BlocConsumer<ChatBloc, ChatState>(
                      listener: (context, state) {
                        if (state is ChatStateLoaded) {
                          _scrollToBottom();
                        }
                        if (state is ChatStateError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message)),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is ChatStateLoading ||
                            state is ChatStateIdle) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColor.orange,
                            ),
                          );
                        }

                        if (state is ChatStateLoaded) {
                          if (state.messages.isEmpty) {
                            return _buildEmptyChat(widthScale, heightScale);
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(
                              16 * widthScale,
                              12 * heightScale,
                              16 * widthScale,
                              12 * heightScale,
                            ),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final msg = state.messages[index];
                              final isMine =
                                  msg.sender == ChatSender.user;
                              return _MessageBubble(
                                message: msg,
                                isMine: isMine,
                                widthScale: widthScale,
                              );
                            },
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),

                  // ───── Input bar OR closed banner ─────
                  if (isClosed)
                    Padding(
                      padding: EdgeInsets.only(bottom: bottomInset),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          16 * widthScale,
                          12 * heightScale,
                          16 * widthScale,
                          16 * heightScale,
                        ),
                        color: const Color(0xFFF5F5F5),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14 * widthScale,
                            vertical: 12 * heightScale,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDECF),
                            borderRadius:
                                BorderRadius.circular(14 * widthScale),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: AppColor.orange,
                                size: 18 * widthScale,
                              ),
                              SizedBox(width: 8 * widthScale),
                              Expanded(
                                child: Text(
                                  'This order is closed. You can\'t send new messages.',
                                  style: TextStyle(
                                    color: AppColor.orange,
                                    fontSize: 12 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.only(bottom: bottomInset),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          16 * widthScale,
                          10 * heightScale,
                          16 * widthScale,
                          14 * heightScale,
                        ),
                        color: const Color(0xFFF5F5F5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                constraints: BoxConstraints(
                                  minHeight: 44 * widthScale,
                                  maxHeight: 110 * widthScale,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16 * widthScale,
                                  vertical: 4 * heightScale,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(24 * widthScale),
                                  border: Border.all(color: AppColor.divider),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  maxLines: null,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: TextStyle(
                                    color: AppColor.textDark,
                                    fontSize: 14 * widthScale,
                                    fontFamily: 'League Spartan',
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Type a message…',
                                    hintStyle: TextStyle(
                                      color: AppColor.gray,
                                      fontSize: 13 * widthScale,
                                      fontFamily: 'League Spartan',
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 10 * heightScale),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10 * widthScale),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 46 * widthScale,
                                height: 46 * widthScale,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColor.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.white,
                                  size: 22 * widthScale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat(double widthScale, double heightScale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40 * widthScale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColor.orange,
              size: 56 * widthScale,
            ),
            SizedBox(height: 16 * heightScale),
            Text(
              'No messages yet',
              style: TextStyle(
                color: AppColor.textDark,
                fontSize: 18 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6 * heightScale),
            Text(
              'Send a message if you need to change something on your order.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColor.gray,
                fontSize: 13 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortId(String id) {
    if (id.length >= 4) return id.substring(id.length - 4).toUpperCase();
    return id.toUpperCase();
  }
}

// ============================================================
// MESSAGE BUBBLE
// ============================================================
class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;
  final double widthScale;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.widthScale,
  });

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? AppColor.orange : Colors.white;
    final textColor = isMine ? Colors.white : AppColor.textDark;
    final timeColor = isMine
        ? Colors.white.withOpacity(0.75)
        : AppColor.gray;

    return Padding(
      padding: EdgeInsets.only(bottom: 10 * widthScale),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 0.75 * MediaQuery.of(context).size.width,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * widthScale,
              vertical: 10 * widthScale,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18 * widthScale),
                topRight: Radius.circular(18 * widthScale),
                bottomLeft: Radius.circular(isMine ? 18 * widthScale : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18 * widthScale),
              ),
              border: isMine
                  ? null
                  : Border.all(color: AppColor.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4 * widthScale),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: timeColor,
                    fontSize: 10 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}