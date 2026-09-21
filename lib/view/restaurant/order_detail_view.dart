// ============================================================
// RESTAURANT ORDER DETAIL VIEW — matches app's visual style
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';
import 'package:forfood/view/restaurant/incoming_order.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/order/order_bloc.dart';
import 'package:forfood/service/order/order_event.dart';
import 'package:forfood/service/order/order_state.dart';
import 'package:forfood/utilities/haptic_feedback.dart';
import 'package:forfood/utilities/page_transition.dart';

import 'package:forfood/view/restaurant/home_page.dart';
import 'package:forfood/view/restaurant/menu.dart';
import 'package:forfood/view/restaurant/order_chat_view.dart';
import 'package:forfood/view/restaurant/profile.dart';

class RestaurantOrderDetailView extends StatefulWidget {
  final String orderId;
  final OrderModel initialOrder;

  const RestaurantOrderDetailView({
    super.key,
    required this.orderId,
    required this.initialOrder,
  });

  @override
  State<RestaurantOrderDetailView> createState() =>
      _RestaurantOrderDetailViewState();
}

class _RestaurantOrderDetailViewState
    extends State<RestaurantOrderDetailView> {
  int _currentIndex = 1;

  // ─── live order lookup ────────────────────────────────────
  OrderModel _liveOrder(OrderState state) {
    List<OrderModel>? pool;
    if (state is OrderStateLoaded) {
      pool = state.orders;
    } else if (state is OrderStateSuccess && state.currentOrders != null) {
      pool = state.currentOrders;
    }
    if (pool != null) {
      final match = pool.where((o) => o.id == widget.orderId).toList();
      if (match.isNotEmpty) return match.first;
    }
    return widget.initialOrder;
  }

  // ─── actions ──────────────────────────────────────────────
  void _handleProgress() {
    HapticFeedbackUtil.medium();
    context.read<OrderBloc>().add(
          OrderEventProgressToNextStage(orderId: widget.orderId),
        );
  }

  Future<void> _handleReject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.nearWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Reject this order?',
          style: TextStyle(
            color: AppColor.textDark,
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'The customer will be notified. This can\'t be undone.',
          style: TextStyle(
            color: AppColor.gray,
            fontFamily: 'League Spartan',
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColor.gray,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, reject',
              style: TextStyle(
                color: AppColor.red,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    HapticFeedbackUtil.heavy();
    context.read<OrderBloc>().add(
          OrderEventRejectOrder(orderId: widget.orderId),
        );

    if (mounted) Navigator.pop(context);
  }

  void _openChat(OrderModel order) {
    HapticFeedbackUtil.light();
    Navigator.of(context).push(
      fadeSlideRoute(RestaurantOrderChatView(order: order)),
    );
  }

  Future<void> _openMap(String address) async {
    if (address.isEmpty) return;
    final encoded = Uri.encodeComponent(address);
    final url = Uri.parse(
      'https://www.openstreetmap.org/search?query=$encoded',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to open map: $e');
    }
  }
void _handleBottomNavTap(int index) {
  if (index == _currentIndex) return;

  switch (index) {
    case 0:
      Navigator.of(context).pushAndRemoveUntil(
        tabRoute(const RestaurantHomeView()),
        (route) => false,
      );
      break;
    case 1:
      Navigator.of(context).pushAndRemoveUntil(
        tabRoute(const OrdersView()),
        (route) => false,
      );
      break;
    case 2:
      Navigator.of(context).push(tabRoute(const ChatInboxView()));
      break;
    case 3:
      Navigator.of(context).push(tabRoute(const MenuListView()));
      break;
    case 4:
      Navigator.of(context).push(
        tabRoute(const ProfileViewRestaurant()),
      );
      break;
  }
}

  // ─── build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String restaurantName = '';
        String restaurantEmail = '';
        String? profileImageUrl;
        if (authState is AuthStateLoggedIn) {
          restaurantName = authState.user.fullName;
          restaurantEmail = authState.user.email;
          profileImageUrl = authState.user.profileImageUrl;
        }

        return BlocBuilder<OrderBloc, OrderState>(
          builder: (context, orderState) {
            final order = _liveOrder(orderState);
            final isTerminal = order.status.isTerminal;

            return Scaffold(
              endDrawer: buildRestaurantDrawer(
                name: restaurantName,
                email: restaurantEmail,
                profileImageUrl: profileImageUrl,
              ),
              body: Container(
                width: screenWidth,
                height: screenHeight,
                color: const Color(0xFFF5CB58),
                child: Stack(
                  children: [
                    // ─── White bottom section ───
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

                    // ─── Back arrow ───
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

                    // ─── Title ───
                    Positioned(
                      left: 75 * widthScale,
                      top: 76 * heightScale,
                      right: 75 * widthScale,
                      child: Text(
                        'Order #${_shortId(order.id)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColor.offWhite,
                          fontSize: 26 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // ─── Chat icon top right ───
                    Positioned(
                      right: 20 * widthScale,
                      top: 76 * heightScale,
                      child: GestureDetector(
                        onTap: () => _openChat(order),
                        child: Container(
                          width: 36 * widthScale,
                          height: 36 * widthScale,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(10 * widthScale),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColor.orange,
                            size: 20 * widthScale,
                          ),
                        ),
                      ),
                    ),

                    // ─── Content ───
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 195 * heightScale,
                      bottom: 0,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24 * widthScale,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10 * heightScale),

                            // ─── Status banner ───
                            _StatusBanner(
                              order: order,
                              widthScale: widthScale,
                            ),
                            SizedBox(height: 20 * heightScale),

                            // ─── Customer section ───
                            _SectionTitle('Customer',
                                widthScale: widthScale),
                            SizedBox(height: 8 * heightScale),
                            _CustomerCard(
                              order: order,
                              widthScale: widthScale,
                            ),
                            SizedBox(height: 20 * heightScale),

                            // ─── Delivery / Pickup ───
                            _SectionTitle(
                              order.deliveryMethod ==
                                      DeliveryMethod.delivery
                                  ? 'Deliver to'
                                  : 'Pickup',
                              widthScale: widthScale,
                            ),
                            SizedBox(height: 8 * heightScale),
                            _AddressCard(
                              order: order,
                              widthScale: widthScale,
                              onSeeMap: () => _openMap(
                                order.deliveryAddress ?? '',
                              ),
                            ),
                            SizedBox(height: 20 * heightScale),

                            // ─── Items ───
                            _SectionTitle('Items',
                                widthScale: widthScale),
                            SizedBox(height: 8 * heightScale),
                            _ItemsCard(
                              order: order,
                              widthScale: widthScale,
                            ),
                            SizedBox(height: 20 * heightScale),

                            // ─── Total ───
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * widthScale,
                                vertical: 14 * heightScale,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      color: AppColor.textDark,
                                      fontSize: 16 * widthScale,
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
                            ),

                            SizedBox(height: 30 * heightScale),

                            // ─── Actions ───
                            if (!isTerminal) ...[
                              if (order.status == OrderStatus.pending)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SecondaryButton(
                                        label: 'Reject',
                                        onTap: _handleReject,
                                        widthScale: widthScale,
                                        heightScale: heightScale,
                                      ),
                                    ),
                                    SizedBox(width: 12 * widthScale),
                                    Expanded(
                                      flex: 2,
                                      child: _PrimaryButton(
                                        label: order.status
                                                .nextActionLabel ??
                                            'Accept',
                                        onTap: _handleProgress,
                                        widthScale: widthScale,
                                        heightScale: heightScale,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                _PrimaryButton(
                                  label: order.status.nextActionLabel ??
                                      'Next Step',
                                  onTap: _handleProgress,
                                  widthScale: widthScale,
                                  heightScale: heightScale,
                                  fullWidth: true,
                                ),
                            ] else
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: 14 * heightScale,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFDECF),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  order.status == OrderStatus.rejected
                                      ? 'This order was rejected'
                                      : order.status ==
                                              OrderStatus.cancelled
                                          ? 'This order was cancelled'
                                          : 'Order completed',
                                  style: TextStyle(
                                    color: AppColor.orange,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15 * widthScale,
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
                isRestaurant: true,
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
// STATUS BANNER
// ============================================================
class _StatusBanner extends StatelessWidget {
  final OrderModel order;
  final double widthScale;

  const _StatusBanner({required this.order, required this.widthScale});

  String get _label {
    switch (order.status) {
      case OrderStatus.pending:
        return 'Awaiting your acceptance';
      case OrderStatus.accepted:
        return 'Accepted — start preparing';
      case OrderStatus.preparing:
        return 'Preparing the food';
      case OrderStatus.readyForPickup:
        return 'Ready for pickup';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTerminal = order.status.isTerminal;
    final bg = isTerminal ? const Color(0xFFFFDECF) : AppColor.orange;
    final fg = isTerminal ? AppColor.orange : Colors.white;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * widthScale),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isTerminal ? Icons.info_outline : Icons.access_time,
            color: fg,
            size: 22 * widthScale,
          ),
          SizedBox(width: 10 * widthScale),
          Expanded(
            child: Text(
              _label,
              style: TextStyle(
                color: fg,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w700,
                fontSize: 15 * widthScale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================
class _SectionTitle extends StatelessWidget {
  final String text;
  final double widthScale;

  const _SectionTitle(this.text, {required this.widthScale});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColor.textDark,
        fontFamily: 'League Spartan',
        fontWeight: FontWeight.w700,
        fontSize: 15 * widthScale,
      ),
    );
  }
}

// ============================================================
// CUSTOMER CARD
// ============================================================
class _CustomerCard extends StatelessWidget {
  final OrderModel order;
  final double widthScale;

  const _CustomerCard({required this.order, required this.widthScale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * widthScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.customerName,
            style: TextStyle(
              color: AppColor.textDark,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w700,
              fontSize: 15 * widthScale,
            ),
          ),
          if (order.customerPhone != null &&
              order.customerPhone!.isNotEmpty) ...[
            SizedBox(height: 4 * widthScale),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: AppColor.orange,
                  size: 14 * widthScale,
                ),
                SizedBox(width: 6 * widthScale),
                Text(
                  order.customerPhone!,
                  style: TextStyle(
                    color: AppColor.textDark,
                    fontFamily: 'League Spartan',
                    fontSize: 13 * widthScale,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 4 * widthScale),
          Row(
            children: [
              Icon(
                Icons.email_outlined,
                color: AppColor.orange,
                size: 14 * widthScale,
              ),
              SizedBox(width: 6 * widthScale),
              Expanded(
                child: Text(
                  order.customerEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColor.textDark,
                    fontFamily: 'League Spartan',
                    fontSize: 13 * widthScale,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADDRESS CARD — with "See in map" for delivery
// ============================================================
class _AddressCard extends StatelessWidget {
  final OrderModel order;
  final double widthScale;
  final VoidCallback onSeeMap;

  const _AddressCard({
    required this.order,
    required this.widthScale,
    required this.onSeeMap,
  });

  @override
  Widget build(BuildContext context) {
    final isDelivery = order.deliveryMethod == DeliveryMethod.delivery;

    final text = isDelivery
        ? (order.deliveryAddress ?? 'No address provided')
        : 'Customer will pick up from your restaurant.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * widthScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isDelivery
                    ? Icons.location_on_outlined
                    : Icons.storefront_outlined,
                color: AppColor.orange,
                size: 18 * widthScale,
              ),
              SizedBox(width: 10 * widthScale),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: AppColor.textDark,
                    fontFamily: 'League Spartan',
                    fontSize: 13 * widthScale,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (isDelivery &&
              order.deliveryAddress != null &&
              order.deliveryAddress!.isNotEmpty) ...[
            SizedBox(height: 12 * widthScale),
            GestureDetector(
              onTap: onSeeMap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14 * widthScale,
                  vertical: 8 * widthScale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDECF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: AppColor.orange,
                      size: 16 * widthScale,
                    ),
                    SizedBox(width: 6 * widthScale),
                    Text(
                      'See in map',
                      style: TextStyle(
                        color: AppColor.orange,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w600,
                        fontSize: 13 * widthScale,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// ITEMS CARD
// ============================================================
class _ItemsCard extends StatelessWidget {
  final OrderModel order;
  final double widthScale;

  const _ItemsCard({required this.order, required this.widthScale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * widthScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: order.items.map((item) {
          final unavailable =
              order.unavailableItems.contains(item.menuItemId);
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 6 * widthScale),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: unavailable
                              ? AppColor.gray
                              : AppColor.textDark,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w600,
                          fontSize: 14 * widthScale,
                          decoration: unavailable
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (unavailable)
                        Text(
                          'Unavailable',
                          style: TextStyle(
                            color: AppColor.red,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w500,
                            fontSize: 11 * widthScale,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  'x${item.quantity}',
                  style: TextStyle(
                    color: AppColor.gray,
                    fontFamily: 'League Spartan',
                    fontSize: 13 * widthScale,
                  ),
                ),
                SizedBox(width: 12 * widthScale),
                Text(
                  '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColor.textDark,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w700,
                    fontSize: 14 * widthScale,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// BUTTONS
// ============================================================
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double widthScale;
  final double heightScale;
  final bool fullWidth;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.widthScale,
    required this.heightScale,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(vertical: 14 * heightScale),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColor.orange,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w700,
            fontSize: 15 * widthScale,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double widthScale;
  final double heightScale;

  const _SecondaryButton({
    required this.label,
    required this.onTap,
    required this.widthScale,
    required this.heightScale,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14 * heightScale),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFDECF),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColor.red,
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w700,
            fontSize: 15 * widthScale,
          ),
        ),
      ),
    );
  }
}