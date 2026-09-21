// ============================================================
// CHAT INBOX — all orders that have a conversation
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/order/order_bloc.dart';
import 'package:forfood/service/order/order_event.dart';
import 'package:forfood/service/order/order_state.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/chat/char_read_tracker.dart';

import 'package:forfood/view/restaurant/order_chat_view.dart';
import 'package:forfood/view/restaurant/home_page.dart';
import 'package:forfood/view/restaurant/incoming_order.dart';
import 'package:forfood/view/restaurant/menu.dart';
import 'package:forfood/view/restaurant/profile.dart';
import 'package:forfood/view/user/order_chat_view.dart';
import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/my_order_view.dart';
import 'package:forfood/view/user/profile.dart';
import 'package:forfood/view/user/search_screen.dart';

class ChatInboxView extends StatefulWidget {
  const ChatInboxView({super.key});

  @override
  State<ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends State<ChatInboxView> {
  int _currentIndex = 2;

  bool get _isRestaurant {
    final s = context.read<AuthBloc>().state;
    return s is AuthStateLoggedIn && s.user.role == UserRole.restaurant;
  }

  Future<bool> _isUnread(OrderModel order) async {
    if (order.lastMessageAt == null) return false;
    final myRole = _isRestaurant ? 'restaurant' : 'user';
    if (order.lastMessageBy == myRole) return false;

    final lastRead = await ChatReadTracker.lastReadAt(order.id);
    if (lastRead == null) return true;
    return order.lastMessageAt!.isAfter(lastRead);
  }

  void _openChat(OrderModel order) {
    ChatReadTracker.markReadNow(order.id);
    Navigator.of(context)
        .push(fadeSlideRoute(
          _isRestaurant
              ? RestaurantOrderChatView(order: order)
              : OrderChatView(order: order),
        ))
        .then((_) => setState(() {}));
  }

  void _handleBottomNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          fadeSlideRoute(_isRestaurant
              ? const RestaurantHomeView()
              : const UserHomeView()),
          (r) => false,
        );
        break;
      case 1:
        Navigator.of(context).push(fadeSlideRoute(
          _isRestaurant ? const OrdersView() : const SearchView(),
        ));
        break;
      case 3:
        Navigator.of(context).push(fadeSlideRoute(
          _isRestaurant ? const MenuListView() : const MyOrdersView(),
        ));
        break;
      case 4:
        Navigator.of(context).push(fadeSlideRoute(_isRestaurant
            ? const ProfileViewRestaurant()
            : const UserProfileView()));
        break;
    }
  }
  Future<void> _refreshInbox() async {
  final authState = context.read<AuthBloc>().state;
  if (authState is! AuthStateLoggedIn) return;

  if (_isRestaurant) {
    // Restaurant: re-fetch orders for this restaurant
    final restaurantId = await _resolveRestaurantId(authState.user.id);
    if (restaurantId == null) return;

    context.read<OrderBloc>().add(
          OrderEventFetchRestaurantOrders(restaurantId: restaurantId),
        );
  } else {
    // User: re-fetch own orders
    context.read<OrderBloc>().add(
          OrderEventFetchUserOrders(userId: authState.user.id),
        );
  }

  // Small delay so the spinner feels intentional
  await Future.delayed(const Duration(milliseconds: 600));
}

Future<String?> _resolveRestaurantId(String ownerId) async {
  try {
    final restaurant = await FirestoreProvider()
        .getRestaurantByOwnerId(ownerId);
    return restaurant?.id;
  } catch (_) {
    return null;
  }
}


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = '';
        String userEmail = '';
        String? profileImageUrl;
        bool isRestaurant = false;

        if (authState is AuthStateLoggedIn) {
          userName = authState.user.fullName;
          userEmail = authState.user.email;
          profileImageUrl = authState.user.profileImageUrl;
          isRestaurant = authState.user.role == UserRole.restaurant;
        }

        return Scaffold(
          endDrawer: isRestaurant
              ? buildRestaurantDrawer(
                  name: userName,
                  email: userEmail,
                  profileImageUrl: profileImageUrl,
                )
              : buildUserDrawer(
                  name: userName,
                  email: userEmail,
                  profileImageUrl: profileImageUrl,
                ),
          body: Container(
            width: screenWidth,
            height: screenHeight,
            color: const Color(0xFFF5CB58),
            child: Stack(
              children: [
                // White rounded bottom section — same as every screen
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

                // Title
                Positioned(
                  top: 76 * heightScale,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Messages',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColor.nearWhite,
                      fontSize: 28 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // List
                Positioned(
                  left: 0,
                  right: 0,
                  top: 163 * heightScale,
                  bottom: 0,
                  child: BlocBuilder<OrderBloc, OrderState>(
                    builder: (context, orderState) {
                      List<OrderModel>? orders;
                      if (orderState is OrderStateLoaded) {
                        orders = orderState.orders;
                      } else if (orderState is OrderStateSuccess &&
                          orderState.currentOrders != null) {
                        orders = orderState.currentOrders;
                      }

                      if (orders == null) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColor.orange,
                          ),
                        );
                      }

                      final withChat = orders
                          .where((o) => o.lastMessageAt != null)
                          .toList()
                        ..sort((a, b) =>
                            b.lastMessageAt!.compareTo(a.lastMessageAt!));

                      if (withChat.isEmpty) {
                        return _buildEmpty(widthScale, heightScale);
                      }

                       return RefreshIndicator(
  color: AppColor.orange,
  onRefresh: _refreshInbox,
  child:ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20 * widthScale,
                          vertical: 16 * heightScale,
                        ),
                        itemCount: withChat.length,
                        separatorBuilder: (_, __) => Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 12 * heightScale),
                          child: Divider(color: AppColor.divider),
                        ),
                        itemBuilder: (context, i) {
                          final order = withChat[i];
                          return _ConversationTile(
                            order: order,
                            isRestaurant: isRestaurant,
                            isUnreadCheck: () => _isUnread(order),
                            onTap: () => _openChat(order),
                            widthScale: widthScale,
                          );
                        },), 
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: _handleBottomNavTap,
            isRestaurant: isRestaurant,
          ),
        );
      },
    );
  }

  Widget _buildEmpty(double widthScale, double heightScale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40 * widthScale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColor.orange,
              size: 64 * widthScale,
            ),
            SizedBox(height: 20 * heightScale),
            Text(
              'No messages yet',
              style: TextStyle(
                color: AppColor.textDark,
                fontSize: 20 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8 * heightScale),
            Text(
              'Start a conversation from any active order.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColor.gray,
                fontSize: 14 * widthScale,
                fontFamily: 'League Spartan',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CONVERSATION TILE — matches your card style
// ============================================================
class _ConversationTile extends StatelessWidget {
  final OrderModel order;
  final bool isRestaurant;
  final Future<bool> Function() isUnreadCheck;
  final VoidCallback onTap;
  final double widthScale;

  const _ConversationTile({
    required this.order,
    required this.isRestaurant,
    required this.isUnreadCheck,
    required this.onTap,
    required this.widthScale,
  });

  String get _displayName =>
      isRestaurant ? order.customerName : order.restaurantName;

  String get _initial {
    final n = _displayName.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  String get _preview {
    final count = order.items.length;
    return '$count item${count == 1 ? '' : 's'}';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isUnreadCheck(),
      builder: (context, snap) {
        final isUnread = snap.data ?? false;

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              // Avatar — initial in a circle
              Container(
                width: 52 * widthScale,
                height: 52 * widthScale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColor.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _initial,
                  style: TextStyle(
                    color: AppColor.orange,
                    fontSize: 20 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 12 * widthScale),

              // Name + preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColor.textDark,
                        fontFamily: 'League Spartan',
                        fontWeight: isUnread
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 16 * widthScale,
                      ),
                    ),
                    SizedBox(height: 2 * widthScale),
                    Text(
                      _preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColor.gray,
                        fontFamily: 'League Spartan',
                        fontSize: 13 * widthScale,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Time + unread dot
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    order.lastMessageAt != null
                        ? _timeAgo(order.lastMessageAt!)
                        : '',
                    style: TextStyle(
                      color: isUnread ? AppColor.orange : AppColor.gray,
                      fontFamily: 'League Spartan',
                      fontSize: 12 * widthScale,
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 6 * widthScale),
                  if (isUnread)
                    Container(
                      width: 10 * widthScale,
                      height: 10 * widthScale,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    SizedBox(height: 10 * widthScale),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}