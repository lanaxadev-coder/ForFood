// ============================================================
// NOTIFICATION DRAWER
// ============================================================
// Drawer shown when user taps the notification bell icon.
// Notifications deep-link into chat / order detail / tracking /
// reviews.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/skeleton_loader.dart';
import 'package:forfood/models/notification_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/notification/notification_bloc.dart';
import 'package:forfood/service/notification/notification_event.dart';
import 'package:forfood/service/notification/notification_state.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/restaurant/order_chat_view.dart';
import 'package:forfood/view/restaurant/order_detail_view.dart';
import 'package:forfood/view/restaurant/review_view.dart';
import 'package:forfood/view/user/order_chat_view.dart';
import 'package:forfood/view/user/order_tracking_view.dart';

class NotificationDrawer extends StatelessWidget {
  const NotificationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is NotificationStateLoading) {
          return _buildSkeletonDrawer();
        }

        if (state is NotificationStateLoaded) {
          return _buildDrawer(
            context: context,
            notifications: state.notifications,
            unreadCount: state.unreadCount,
          );
        }

        return _buildEmptyDrawer();
      },
    );
  }

  // ============================================================
  // SKELETON
  // ============================================================
  Widget _buildSkeletonDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70),
          bottomLeft: Radius.circular(70),
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const ShapeDecoration(
          color: AppColor.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              bottomLeft: Radius.circular(60),
            ),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const _Header(unreadCount: 0),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 4,
                itemBuilder: (context, index) =>
                    const NotificationTileSkeleton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADED
  // ============================================================
  Widget _buildDrawer({
    required BuildContext context,
    required List<NotificationModel> notifications,
    required int unreadCount,
  }) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70),
          bottomLeft: Radius.circular(70),
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const ShapeDecoration(
          color: AppColor.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              bottomLeft: Radius.circular(60),
            ),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            _Header(unreadCount: unreadCount),
            Expanded(
              child: notifications.isEmpty
                  ? const _EmptyNotifications()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: const Color(0xFFFFDECF)),
                      ),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _NotificationTile(
                          notification: notification,
                          onTap: () =>
                              _handleNotificationTap(context, notification),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================
  Widget _buildEmptyDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70),
          bottomLeft: Radius.circular(70),
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const ShapeDecoration(
          color: AppColor.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              bottomLeft: Radius.circular(60),
            ),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const _Header(unreadCount: 0),
            const Expanded(child: _EmptyNotifications()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TAP HANDLER — mark read + deep link
  // ============================================================
  Future<void> _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) async {
    // 1. Capture before any await
    final notificationBloc = context.read<NotificationBloc>();
    final authState = context.read<AuthBloc>().state;
    final navigator = Navigator.of(context);

    // 2. Mark as read
    notificationBloc.add(
      NotificationEventMarkAsRead(notificationId: notification.id),
    );

    if (authState is! AuthStateLoggedIn) return;

    final isRestaurant = authState.user.role == UserRole.restaurant;

    // ============================================================
    // ✅ Review notification → Reviews screen (restaurant only)
    //    This has NO orderId, so it must be handled before the check.
    // ============================================================
    if (notification.type == NotificationType.reviewAdded) {
      if (!isRestaurant) return;
      navigator.pop();
      navigator.push(fadeSlideRoute(const ReviewsView()));
      return;
    }

    // ============================================================
    // Order-related notifications need an orderId
    // ============================================================
    if (notification.orderId == null || notification.orderId!.isEmpty) {
      return;
    }

    navigator.pop();

    final orderId = notification.orderId!;

    try {
      final order = await FirestoreProvider().getOrderById(orderId);

      // Chat → open chat
      if (notification.type == NotificationType.chatMessage) {
        navigator.push(
          fadeSlideRoute(
            isRestaurant
                ? RestaurantOrderChatView(order: order)
                : OrderChatView(order: order),
          ),
        );
        return;
      }

      // Everything else → order screens
      if (isRestaurant) {
        navigator.push(
          fadeSlideRoute(
            RestaurantOrderDetailView(
              orderId: order.id,
              initialOrder: order,
            ),
          ),
        );
      } else {
        navigator.push(
          fadeSlideRoute(OrderTrackingView(order: order)),
        );
      }
    } catch (e) {
      debugPrint('Notification deep-link failed: $e');
    }
  }
}

// ============================================================
// HEADER
// ============================================================
class _Header extends StatelessWidget {
  final int unreadCount;
  const _Header({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: SvgPicture.asset(
                    'assets/icons/Notification Icon.svg',
                    height: 35,
                    width: 35,
                    color: AppColor.offWhite,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: Color(0xFFF8F8F8),
                    fontSize: 25,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            height: 0.75,
            width: 254,
            color: AppColor.yellow,
          ),
          const SizedBox(height: 15),
          Text(
            unreadCount == 0
                ? 'No new notifications'
                : 'You have $unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Color(0xFFF8F8F8),
              fontSize: 18,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NOTIFICATION TILE
// ============================================================
class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Colors.transparent
                  : AppColor.yellow,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: const TextStyle(
                    color: Color(0xFFF8F8F8),
                    fontSize: 14,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRelativeTime(notification.createdAt),
                  style: const TextStyle(
                    color: AppColor.yellow2,
                    fontSize: 12,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      return '$day/$month/${dateTime.year}';
    }
  }
}

// ============================================================
// EMPTY STATE
// ============================================================
class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/Notification Icon.svg',
            height: 80,
            width: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: Color(0xFFF8F8F8),
              fontSize: 20,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'When something happens with your orders,\nwe\'ll let you know here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFF8F8F8).withOpacity(0.7),
              fontSize: 14,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}