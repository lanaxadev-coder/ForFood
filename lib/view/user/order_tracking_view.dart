// ============================================================
// ORDER TRACKING VIEW — live status timeline for a single order
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/network_image_with_shimmer.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/order/order_bloc.dart';
import 'package:forfood/service/order/order_state.dart';
import 'package:forfood/utilities/haptic_feedback.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/user/cancel_order_view.dart';
import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/order_chat_view.dart';
import 'package:forfood/view/user/search_screen.dart';

class OrderTrackingView extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingView({super.key, required this.order});

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> {
  int _currentIndex = 0;

  // ✅ Scaffold key + which drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DrawerType _activeDrawer = DrawerType.profile;

  // ✅ Drawer openers
  void _openProfileDrawer() {
    setState(() => _activeDrawer = DrawerType.profile);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _openCartDrawer() {
    setState(() => _activeDrawer = DrawerType.cart);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _openNotificationDrawer() {
    setState(() => _activeDrawer = DrawerType.notifications);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _handleBottomNavTap(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          fadeSlideRoute(const UserHomeView()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).push(fadeSlideRoute(const SearchView()));
        break;
      case 2:
        Navigator.of(context).push(fadeSlideRoute(const ChatInboxView()));
        break;
      case 3:
            setState(() => _currentIndex = index);   // ✅ highlight

        // ✅ Cart tab → cart drawer
        _openCartDrawer();
        break;
      case 4:
            setState(() => _currentIndex = index);   // ✅ highlight

        // ✅ Profile tab → profile drawer
        _openProfileDrawer();
        break;
    }
  }

  /// Prefer the freshest copy of the order from the live stream.
  OrderModel _liveOrder(OrderState state) {
    List<OrderModel>? pool;
    if (state is OrderStateLoaded) {
      pool = state.orders;
    } else if (state is OrderStateSuccess && state.currentOrders != null) {
      pool = state.currentOrders;
    }
    if (pool != null) {
      final match = pool.where((o) => o.id == widget.order.id).toList();
      if (match.isNotEmpty) return match.first;
    }
    return widget.order;
  }

  // ✅ Picks which drawer renders
  Widget _buildActiveDrawer(
    String userName,
    String userEmail,
    String? profileImageUrl,
  ) {
    switch (_activeDrawer) {
      case DrawerType.profile:
        return buildUserDrawer(
          name: userName,
          email: userEmail,
          profileImageUrl: profileImageUrl,
        );
      case DrawerType.cart:
        return const CartView();
      case DrawerType.notifications:
        return const NotificationDrawer();
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
        if (authState is AuthStateLoggedIn) {
          userName = authState.user.fullName;
          userEmail = authState.user.email;
          profileImageUrl = authState.user.profileImageUrl;
        }

        return BlocBuilder<OrderBloc, OrderState>(
          builder: (context, orderState) {
            final order = _liveOrder(orderState);

            return Scaffold(
              key: _scaffoldKey,
              // ✅ Dynamic drawer
              endDrawer: _buildActiveDrawer(
                userName,
                userEmail,
                profileImageUrl,
              ),
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

                    // Back arrow
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

                    // Title
                    Positioned(
                      left: 90 * widthScale,
                      top: 76 * heightScale,
                      child: Text(
                        'Order #${_shortId(order.id)}',
                        style: TextStyle(
                          color: AppColor.textDark,
                          fontSize: 26 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Positioned(
                      right: 20 * widthScale,
                      top: 70 * heightScale,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedbackUtil.light();
                          Navigator.of(context).push(
                            fadeSlideRoute(OrderChatView(order: order)),
                          );
                        },
                        child: Container(
                          width: 40 * widthScale,
                          height: 40 * widthScale,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColor.orange,
                            size: 20 * widthScale,
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 190 * heightScale,
                      bottom: 0,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24 * widthScale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10 * heightScale),

                            _RestaurantHeader(
                              order: order,
                              widthScale: widthScale,
                            ),
                            SizedBox(height: 20 * heightScale),

                            _StatusHeaderCard(
                              order: order,
                              widthScale: widthScale,
                            ),
                            SizedBox(height: 24 * heightScale),

                            // Timeline OR cancelled banner
                            if (order.status == OrderStatus.cancelled ||
                                order.status == OrderStatus.rejected)
                              _CancelledBanner(
                                order: order,
                                widthScale: widthScale,
                              )
                            else
                              _Timeline(
                                order: order,
                                widthScale: widthScale,
                              ),

                            SizedBox(height: 24 * heightScale),

                            Text(
                              'Items',
                              style: TextStyle(
                                color: AppColor.textDark,
                                fontSize: 18 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 12 * heightScale),

                            ...order.items.map(
                              (item) => _ItemRow(
                                item: item,
                                widthScale: widthScale,
                              ),
                            ),

                            SizedBox(height: 20 * heightScale),
                            Container(height: 1, color: AppColor.divider),
                            SizedBox(height: 16 * heightScale),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    color: AppColor.textDark,
                                    fontSize: 18 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '\$${order.total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: AppColor.orange,
                                    fontSize: 20 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 30 * heightScale),

                            // Cancel button (only if pending)
                            if (order.status == OrderStatus.pending)
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedbackUtil.medium();
                                    Navigator.of(context).push(
                                      fadeSlideRoute(
                                        CancelOrderView(orderId: order.id),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 40 * widthScale,
                                      vertical: 14 * heightScale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFDECF),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      'Cancel Order',
                                      style: TextStyle(
                                        color: AppColor.red,
                                        fontSize: 15 * widthScale,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            SizedBox(height: 40 * heightScale),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: BottomNavBar(
                currentIndex: _currentIndex,
                onTap: _handleBottomNavTap,
              ),
            );
          },
        );
      },
    );
  }

  String _shortId(String id) {
    if (id.length >= 4) return id.substring(id.length - 4).toUpperCase();
    return id.toUpperCase();
  }
}

// ============================================================
// RESTAURANT HEADER
// ============================================================
class _RestaurantHeader extends StatelessWidget {
  final OrderModel order;
  final double widthScale;

  const _RestaurantHeader({required this.order, required this.widthScale});

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44 * widthScale,
          height: 44 * widthScale,
          decoration: BoxDecoration(
            color: AppColor.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.restaurant,
            color: AppColor.orange,
            size: 22 * widthScale,
          ),
        ),
        SizedBox(width: 12 * widthScale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.restaurantName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColor.textDark,
                  fontSize: 17 * widthScale,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2 * widthScale),
              Text(
                'Placed at ${_formatTime(order.createdAt)}',
                style: TextStyle(
                  color: AppColor.gray,
                  fontSize: 13 * widthScale,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STATUS HEADER CARD
// ============================================================
class _StatusHeaderCard extends StatelessWidget {
  final OrderModel order;
  final double widthScale;

  const _StatusHeaderCard({required this.order, required this.widthScale});

  String get _title {
    switch (order.status) {
      case OrderStatus.pending:
        return 'Waiting for confirmation';
      case OrderStatus.accepted:
        return 'Order confirmed';
      case OrderStatus.preparing:
        return 'Being prepared';
      case OrderStatus.readyForPickup:
        return 'Ready for pickup';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.completed:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  String get _subtitle {
    final prep = order.estimatedPrepMinutes;
    switch (order.status) {
      case OrderStatus.pending:
        return 'The restaurant has been notified';
      case OrderStatus.accepted:
        return prep != null
            ? 'Estimated time: ~$prep min'
            : 'The restaurant is preparing to cook';
      case OrderStatus.preparing:
        return prep != null ? 'Ready in ~$prep min' : 'Your food is cooking';
      case OrderStatus.readyForPickup:
        return 'Head over to the restaurant';
      case OrderStatus.outForDelivery:
        return 'On the way to you';
      case OrderStatus.completed:
        return 'Enjoy your meal!';
      case OrderStatus.cancelled:
        return order.cancellationReason ?? 'This order was cancelled';
      case OrderStatus.rejected:
        return 'The restaurant could not accept this order';
    }
  }

  bool get _isTerminal =>
      order.status == OrderStatus.cancelled ||
      order.status == OrderStatus.rejected;

  @override
  Widget build(BuildContext context) {
    final bg = _isTerminal ? const Color(0xFFFFDECF) : AppColor.orange;
    final fg = _isTerminal ? AppColor.orange : Colors.white;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * widthScale),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20 * widthScale),
      ),
      child: Row(
        children: [
          Icon(
            _isTerminal ? Icons.info_outline : Icons.access_time,
            color: fg,
            size: 26 * widthScale,
          ),
          SizedBox(width: 12 * widthScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    color: fg,
                    fontSize: 17 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2 * widthScale),
                Text(
                  _subtitle,
                  style: TextStyle(
                    color: fg.withOpacity(0.9),
                    fontSize: 13 * widthScale,
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
}

// ============================================================
// TIMELINE
// ============================================================
class _Timeline extends StatelessWidget {
  final OrderModel order;
  final double widthScale;

  const _Timeline({required this.order, required this.widthScale});

  int get _stage {
    switch (order.status) {
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.readyForPickup:
      case OrderStatus.outForDelivery:
        return 2;
      case OrderStatus.completed:
        return 3;
      default:
        return 0;
    }
  }

  bool get _isDelivery => order.deliveryMethod == DeliveryMethod.delivery;

  List<String> get _labels {
    if (_isDelivery) {
      return ['Confirmed', 'Preparing', 'Out for delivery', 'Delivered'];
    }
    return ['Confirmed', 'Preparing', 'Ready for pickup', 'Picked up'];
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    final labels = _labels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: TextStyle(
            color: AppColor.textDark,
            fontSize: 18 * widthScale,
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16 * widthScale),
        ...List.generate(4, (i) {
          final isDone = i < stage;
          final isCurrent = i == stage;
          final isLast = i == 3;

          return _TimelineStep(
            label: labels[i],
            isDone: isDone,
            isCurrent: isCurrent,
            showLine: !isLast,
            widthScale: widthScale,
          );
        }),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool showLine;
  final double widthScale;

  const _TimelineStep({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.showLine,
    required this.widthScale,
  });

  @override
  Widget build(BuildContext context) {
    final color = (isDone || isCurrent) ? AppColor.orange : AppColor.gray;
    final lineColor = isDone ? AppColor.orange : AppColor.divider;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28 * widthScale,
          child: Column(
            children: [
              Container(
                width: 20 * widthScale,
                height: 20 * widthScale,
                decoration: BoxDecoration(
                  color: isCurrent ? Colors.white : color,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: isDone
                    ? Icon(Icons.check,
                        color: Colors.white, size: 12 * widthScale)
                    : isCurrent
                        ? Center(
                            child: Container(
                              width: 8 * widthScale,
                              height: 8 * widthScale,
                              decoration: const BoxDecoration(
                                color: AppColor.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
              ),
              if (showLine)
                Container(
                  width: 2,
                  height: 32 * widthScale,
                  color: lineColor,
                ),
            ],
          ),
        ),
        SizedBox(width: 12 * widthScale),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDone || isCurrent
                  ? AppColor.textDark
                  : AppColor.gray,
              fontSize: 15 * widthScale,
              fontFamily: 'League Spartan',
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        if (isCurrent)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * widthScale,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColor.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'NOW',
              style: TextStyle(
                color: AppColor.orange,
                fontSize: 10 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// CANCELLED BANNER
// ============================================================
class _CancelledBanner extends StatelessWidget {
  final OrderModel order;
  final double widthScale;

  const _CancelledBanner({required this.order, required this.widthScale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * widthScale),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDECF),
        borderRadius: BorderRadius.circular(16 * widthScale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: AppColor.red,
                size: 20 * widthScale,
              ),
              SizedBox(width: 8 * widthScale),
              Text(
                order.status == OrderStatus.rejected
                    ? 'Order rejected'
                    : 'Order cancelled',
                style: TextStyle(
                  color: AppColor.red,
                  fontSize: 15 * widthScale,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (order.cancellationReason != null &&
              order.cancellationReason!.isNotEmpty) ...[
            SizedBox(height: 6 * widthScale),
            Text(
              order.cancellationReason!,
              style: TextStyle(
                color: AppColor.textDark.withOpacity(0.8),
                fontSize: 13 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// ITEM ROW
// ============================================================
class _ItemRow extends StatelessWidget {
  final OrderItem item;
  final double widthScale;

  const _ItemRow({required this.item, required this.widthScale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * widthScale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: NetworkImageWithShimmer(
              imageUrl: item.imageUrl ?? 'https://placehold.co/44x44',
              width: 44 * widthScale,
              height: 44 * widthScale,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 12 * widthScale),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColor.textDark,
                fontSize: 14 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'x${item.quantity}',
            style: TextStyle(
              color: AppColor.gray,
              fontSize: 13 * widthScale,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 12 * widthScale),
          Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            style: TextStyle(
              color: AppColor.textDark,
              fontSize: 14 * widthScale,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}