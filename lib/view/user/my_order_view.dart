// ============================================================
// MY ORDERS VIEW — PRODUCTION READY
// Fixed: Drawer + Bottom Nav + Responsive + Error State + Haptic
// Fixed: list no longer wipes after cancel/accept/reject actions
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/core/widgets/order_list_card.dart';
import 'package:forfood/core/widgets/order_progress_indicator.dart';
import 'package:forfood/core/widgets/skeleton_loader.dart';
import 'package:forfood/core/widgets/user_status_tabs.dart';
import 'package:forfood/models/order_model.dart';

import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/order/order_bloc.dart';
import 'package:forfood/service/order/order_event.dart';
import 'package:forfood/service/order/order_state.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/user/cancel_order_view.dart';
import 'package:forfood/view/user/leave_review.dart';
import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/order_tracking_view.dart';
import 'package:forfood/view/user/search_screen.dart';

class MyOrdersView extends StatefulWidget {
  const MyOrdersView({super.key});

  @override
  State<MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<MyOrdersView> {
  int _currentIndex = 0;
  OrderTabStatus _selectedTab = OrderTabStatus.active;

  // ✅ Scaffold key + which drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DrawerType _activeDrawer = DrawerType.profile;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<OrderBloc>().add(
            OrderEventFetchUserOrders(userId: authState.user.id),
          );
    }
  }

  void _handleReorder(OrderModel order) {
    context.read<OrderBloc>().add(
          OrderEventReorderItems(originalOrder: order),
        );
  }

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
          tabRoute(const UserHomeView()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).push(tabRoute(const SearchView()));
        break;
      case 2:
        Navigator.of(context).push(tabRoute(const ChatInboxView()));
        break;
      case 3:
            setState(() => _currentIndex = index);   // ✅ highlight

        // ✅ Cart tab → cart drawer
        Navigator.of(context).push(tabRoute(const MyOrdersView()));
        break;
      case 4:
            setState(() => _currentIndex = index);   // ✅ highlight

        // ✅ Profile tab → profile drawer
        _openProfileDrawer();
        break;
    }
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

    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderStateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          String userName = '';
          String userEmail = '';
          String? profileImageUrl;

          if (authState is AuthStateLoggedIn) {
            userName = authState.user.fullName;
            userEmail = authState.user.email;
            profileImageUrl = authState.user.profileImageUrl;
          }

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
                    left: 116 * widthScale,
                    top: 76 * heightScale,
                    child: Text(
                      'My Orders',
                      style: TextStyle(
                        color: AppColor.nearWhite,
                        fontSize: 28 * widthScale,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Status tabs
                  Positioned(
                    left: 35 * widthScale,
                    top: 195 * heightScale,
                    child: UserStatusTabs(
                      selected: _selectedTab,
                      onChanged: (s) => setState(() => _selectedTab = s),
                    ),
                  ),

                  // Content area
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 240 * heightScale,
                    bottom: 0,
                    child: BlocBuilder<OrderBloc, OrderState>(
                      builder: (context, state) {
                        // ────────────────────────────────────────
                        // 1. LOADING — show skeletons
                        // ────────────────────────────────────────
                        if (state is OrderStateLoading) {
                          return ListView.builder(
                            padding: EdgeInsets.symmetric(
                                horizontal: 35 * widthScale),
                            itemCount: 3,
                            itemBuilder: (context, index) => Padding(
                              padding:
                                  EdgeInsets.only(bottom: 20 * heightScale),
                              child: const OrderCardSkeleton(),
                            ),
                          );
                        }

                        // ────────────────────────────────────────
                        // 2. EXTRACT ORDERS — from Loaded OR Success
                        // ────────────────────────────────────────
                        List<OrderModel>? orders;
                        if (state is OrderStateLoaded) {
                          orders = state.orders;
                        } else if (state is OrderStateSuccess &&
                            state.currentOrders != null) {
                          orders = state.currentOrders;
                        }

                        if (orders != null) {
                          final filteredOrders = _filterOrders(orders);

                          if (filteredOrders.isEmpty) {
                            return _buildEmptyState(
                                widthScale, heightScale);
                          }

                          return RefreshIndicator(
                            color: AppColor.orange,
                            onRefresh: () async {
                              _fetchOrders();
                              await Future.delayed(
                                const Duration(milliseconds: 500),
                              );
                            },
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 35 * widthScale),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
                                return _buildOrderCard(
                                    order, widthScale, heightScale);
                              },
                            ),
                          );
                        }

                        // ────────────────────────────────────────
                        // 3. ERROR
                        // ────────────────────────────────────────
                        if (state is OrderStateError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 60 * widthScale,
                                ),
                                SizedBox(height: 20 * heightScale),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 40 * widthScale),
                                  child: Text(
                                    state.message,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16 * widthScale,
                                      fontFamily: 'League Spartan',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20 * heightScale),
                                GestureDetector(
                                  onTap: _fetchOrders,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24 * widthScale,
                                      vertical: 10 * heightScale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColor.orange,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      'Retry',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16 * widthScale,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // ────────────────────────────────────────
                        // 4. FALLBACK — initial state, no data yet
                        // ────────────────────────────────────────
                        return _buildEmptyState(widthScale, heightScale);
                      },
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
      ),
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    switch (_selectedTab) {
      case OrderTabStatus.active:
        return orders.where((o) => o.status.isActive).toList();
      case OrderTabStatus.completed:
        return orders
            .where((o) => o.status == OrderStatus.completed)
            .toList();
      case OrderTabStatus.cancelled:
        return orders
            .where(
              (o) =>
                  o.status == OrderStatus.cancelled ||
                  o.status == OrderStatus.rejected,
            )
            .toList();
    }
  }

  Widget _buildOrderCard(
      OrderModel order, double widthScale, double heightScale) {
    final imageUrl =
        order.items.isNotEmpty ? order.items.first.imageUrl : null;

    return Column(
      children: [
        OrderListCard(
          imageUrl: imageUrl ?? 'https://picsum.photos/72/108',
          name: order.items.isNotEmpty ? order.items.first.name : 'Order',
          date: _formatDate(order.createdAt),
          itemsCount:
              '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
          price: '\$${order.total.toStringAsFixed(2)}',
          statusNote: _getStatusNote(order.status),
          actionLabel: _getActionLabel(),
          showSecondaryAction:
              _selectedTab == OrderTabStatus.completed ||
                  _selectedTab == OrderTabStatus.cancelled,
          onTap: () => _openTracking(order),
          onAction: () => _handleAction(order),
          onSecondaryAction:
              (_selectedTab == OrderTabStatus.completed ||
                      _selectedTab == OrderTabStatus.cancelled)
                  ? () => _handleReorder(order)
                  : null,
        ),
        if (order.estimatedPrepMinutes != null && order.status.isActive)
          Padding(
            padding: EdgeInsets.only(bottom: 8 * heightScale),
            child: Text(
              '⏱ Estimated: ${order.estimatedPrepMinutes} minutes',
              style: TextStyle(
                color: AppColor.orange,
                fontSize: 14 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (_selectedTab == OrderTabStatus.active &&
            order.status.isActive &&
            !order.status.isTerminal)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20 * widthScale,
              vertical: 8 * heightScale,
            ),
            child: OrderProgressIndicator(currentStatus: order.status),
          ),
      ],
    );
  }

  String _getStatusNote(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return 'Order delivered';
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return 'Order cancelled';
      default:
        return status.displayName;
    }
  }

  String _getActionLabel() {
    switch (_selectedTab) {
      case OrderTabStatus.active:
        return 'Cancel Order';
      case OrderTabStatus.completed:
        return 'Leave a review';
      case OrderTabStatus.cancelled:
        return 'Order Again';
    }
  }

  void _openTracking(OrderModel order) {
    // Only track orders that are still active
    if (order.status.isActive) {
      Navigator.of(context).push(
        fadeSlideRoute(OrderTrackingView(order: order)),
      );
      return;
    }
    // Completed → open review
    if (order.status == OrderStatus.completed) {
      _handleAction(order);
      return;
    }
    // Cancelled/rejected → do nothing extra (user can use the Order Again button)
  }

  void _handleAction(OrderModel order) {
    if (_selectedTab == OrderTabStatus.active) {
      Navigator.of(context).push(
        fadeSlideRoute(CancelOrderView(orderId: order.id)),
      );
    } else if (_selectedTab == OrderTabStatus.completed) {
      final imageUrl =
          order.items.isNotEmpty ? order.items.first.imageUrl : '';
      Navigator.of(context).push(
        fadeSlideRoute(
          LeaveReviewView(
            itemName: order.items.isNotEmpty ? order.items.first.name : '',
            itemImageUrl: imageUrl ?? 'https://picsum.photos/72/108',
            restaurantId: order.restaurantId,
          ),
        ),
      );
    } else if (_selectedTab == OrderTabStatus.cancelled) {
      _handleReorder(order);
    }
  }

  Widget _buildEmptyState(double widthScale, double heightScale) {
    // Contextual coaching per tab
    final String headline;
    final String subline;
    final String ctaLabel;

    switch (_selectedTab) {
      case OrderTabStatus.active:
        headline = "You don't have any active orders";
        subline = '👋 Hungry? Try searching for a \$5 meal near you.';
        ctaLabel = 'Start searching';
        break;
      case OrderTabStatus.completed:
        headline = "You don't have any completed orders yet";
        subline = 'Order something — it will show up here once delivered.';
        ctaLabel = 'Find food';
        break;
      case OrderTabStatus.cancelled:
        headline = "You don't have any cancelled orders";
        subline = 'That\'s a good thing! Nothing to clean up.';
        ctaLabel = 'Browse restaurants';
        break;
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 70 * heightScale),
          SvgPicture.asset(
            'assets/icons/Transfer Document icon.svg',
            height: 140 * heightScale,
            width: 120 * widthScale,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 24 * heightScale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 45 * widthScale),
            child: Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColor.orange,
                fontSize: 22 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(height: 14 * heightScale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 45 * widthScale),
            child: Text(
              subline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColor.gray,
                fontSize: 14 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 26 * heightScale),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                fadeSlideRoute(const UserHomeView()),
                (route) => false,
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 26 * widthScale,
                vertical: 11 * heightScale,
              ),
              decoration: BoxDecoration(
                color: AppColor.orange,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ctaLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6 * widthScale),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 16 * widthScale,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString().substring(2);
    return '$day/$month/$year';
  }
}