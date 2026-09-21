// ============================================================
// ORDERS VIEW — RESTAURANT SIDE
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/order_card.dart';
import 'package:forfood/core/widgets/skeleton_loader.dart';
import 'package:forfood/models/notification_model.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/order/order_bloc.dart';
import 'package:forfood/service/order/order_event.dart';
import 'package:forfood/service/order/order_state.dart';
import 'package:forfood/service/restaurant/restaurant_bloc.dart';
import 'package:forfood/service/restaurant/restaurant_event.dart';
import 'package:forfood/service/restaurant/restaurant_state.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/restaurant/home_page.dart';
import 'package:forfood/view/restaurant/menu.dart';
import 'package:forfood/view/restaurant/order_detail_view.dart';   // ✅ new import
import 'package:forfood/view/restaurant/profile.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  int _currentIndex = 1;
  String? _restaurantId;

  @override
  void initState() {
    super.initState();
    _fetchRestaurant();
  }

  void _fetchRestaurant() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<RestaurantBloc>().add(
            RestaurantEventFetchByOwnerId(ownerId: authState.user.id),
          );
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

  // ============================================================
  // REPORT ISSUE — bottom sheet with options
  // ============================================================
  Future<void> _openReportIssueSheet(OrderModel order) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColor.nearWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColor.gray.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Report an issue',
                style: TextStyle(
                  color: AppColor.textDark,
                  fontSize: 20,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Let the customer know what\'s wrong.',
                style: TextStyle(
                  color: AppColor.gray,
                  fontSize: 13,
                  fontFamily: 'League Spartan',
                ),
              ),
              const SizedBox(height: 20),

              _issueOption(
                sheetContext,
                icon: Icons.no_food_outlined,
                title: 'An item is unavailable',
                subtitle: 'Customer can decide to remove or cancel',
                value: 'item_unavailable',
              ),
              const SizedBox(height: 10),
              _issueOption(
                sheetContext,
                icon: Icons.timer_outlined,
                title: 'Too busy — running late',
                subtitle: 'Notify the customer about a delay',
                value: 'too_busy',
              ),
              const SizedBox(height: 10),
              _issueOption(
                sheetContext,
                icon: Icons.storefront_outlined,
                title: 'We need to close early',
                subtitle: 'Customer will be offered a full refund',
                value: 'closing',
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    switch (result) {
      case 'item_unavailable':
        await _openItemPickerSheet(order);
        break;
      case 'too_busy':
        await _notifyTooBusy(order);
        break;
      case 'closing':
        await _notifyClosing(order);
        break;
    }
  }

  Widget _issueOption(
    BuildContext sheetContext, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(sheetContext, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColor.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColor.orange, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColor.textDark,
                      fontSize: 14,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColor.gray,
                      fontSize: 12,
                      fontFamily: 'League Spartan',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColor.gray, size: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ITEM PICKER
  // ============================================================
  Future<void> _openItemPickerSheet(OrderModel order) async {
    final selected = <String>{};

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stateContext, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColor.nearWhite,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColor.gray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Which items are unavailable?',
                    style: TextStyle(
                      color: AppColor.textDark,
                      fontSize: 18,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...order.items.map((item) {
                    final isChecked = selected.contains(item.menuItemId);
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          if (isChecked) {
                            selected.remove(item.menuItemId);
                          } else {
                            selected.add(item.menuItemId);
                          }
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? AppColor.orange
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isChecked
                                      ? AppColor.orange
                                      : AppColor.gray,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: isChecked
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${item.name} ×${item.quantity}',
                                style: const TextStyle(
                                  color: AppColor.textDark,
                                  fontSize: 15,
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColor.gray,
                                fontSize: 13,
                                fontFamily: 'League Spartan',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: selected.isEmpty
                          ? null
                          : () => Navigator.pop(sheetContext, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected.isEmpty
                              ? AppColor.gray.withOpacity(0.3)
                              : AppColor.orange,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          'Notify customer',
                          style: TextStyle(
                            color: selected.isEmpty
                                ? AppColor.gray
                                : Colors.white,
                            fontSize: 15,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _applyItemUnavailable(order, selected.toList());
  }

  // ============================================================
  // APPLY — write to Firestore + notify user
  // ============================================================
  Future<void> _applyItemUnavailable(
    OrderModel order,
    List<String> menuItemIds,
  ) async {
    try {
      final firestoreProvider = FirestoreProvider();

      await firestoreProvider.markItemsUnavailable(
        orderId: order.id,
        menuItemIds: menuItemIds,
      );

      final itemNames = order.items
          .where((i) => menuItemIds.contains(i.menuItemId))
          .map((i) => i.name)
          .join(', ');

      final notification = NotificationModel(
        id: '',
        recipientId: order.userId,
        type: NotificationType.orderPlaced,
        title: 'Item unavailable',
        message:
            '${order.restaurantName} is out of: $itemNames. Open the order to decide what to do.',
        orderId: order.id,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await firestoreProvider.createNotification(notification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer notified'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  // ============================================================
  // SIMPLE NOTIFY (too busy / closing)
  // ============================================================
  Future<void> _notifyTooBusy(OrderModel order) async {
    await _sendSimpleNotification(
      order,
      title: 'Running late',
      message:
          '${order.restaurantName} is busier than usual. Your order may take a bit longer.',
    );
  }

  Future<void> _notifyClosing(OrderModel order) async {
    await _sendSimpleNotification(
      order,
      title: 'Restaurant closing',
      message:
          '${order.restaurantName} needs to close. You may want to cancel this order.',
    );
  }

  Future<void> _sendSimpleNotification(
    OrderModel order, {
    required String title,
    required String message,
  }) async {
    try {
      final firestoreProvider = FirestoreProvider();
      await firestoreProvider.createNotification(
        NotificationModel(
          id: '',
          recipientId: order.userId,
          type: NotificationType.orderPlaced,
          title: title,
          message: message,
          orderId: order.id,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer notified'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
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
        if (state is OrderStateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          String restaurantName = '';
          String restaurantEmail = '';
          String? profileImageUrl;

          if (authState is AuthStateLoggedIn) {
            restaurantName = authState.user.fullName;
            restaurantEmail = authState.user.email;
            profileImageUrl = authState.user.profileImageUrl;
          }

          return BlocBuilder<RestaurantBloc, RestaurantState>(
            builder: (context, restaurantState) {
              if (restaurantState is RestaurantStateLoaded) {
                restaurantName = restaurantState.restaurant.name;
                if (_restaurantId != restaurantState.restaurant.id) {
                  _restaurantId = restaurantState.restaurant.id;
                  context.read<OrderBloc>().add(
                        OrderEventFetchRestaurantOrders(
                          restaurantId: _restaurantId!,
                        ),
                      );
                }
              }

              return Scaffold(
                endDrawer: buildRestaurantDrawer(
                  name: restaurantName,
                  email: restaurantEmail,
                  profileImageUrl: profileImageUrl,
                ),
                body: Container(
                  width: screenWidth,
                  height: screenHeight,
                  clipBehavior: Clip.antiAlias,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFF5CB58),
                    shape: RoundedRectangleBorder(),
                  ),
                  child: Stack(
                    children: [
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

                      Positioned(
                        top: 70 * heightScale,
                        left: 150 * widthScale,
                        child: Text(
                          'Orders',
                          style: TextStyle(
                            color: AppColor.offWhite,
                            fontSize: 32 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      Positioned(
                        left: 35 * widthScale,
                        top: 79 * heightScale,
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

                      Positioned(
                        left: 0,
                        right: 0,
                        top: 160 * heightScale,
                        bottom: 0,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                              horizontal: 17 * widthScale),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 30 * heightScale),
                              Text(
                                'Active Orders',
                                style: TextStyle(
                                  color: AppColor.black,
                                  fontSize: 20 * widthScale,
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 10 * heightScale),

                              BlocBuilder<OrderBloc, OrderState>(
                                builder: (context, state) {
                                  // ─ Loading ─
                                  if (state is OrderStateLoading) {
                                    return RefreshIndicator(
                                      color: AppColor.orange,
                                      onRefresh: () async {
                                        _fetchRestaurant();
                                        await Future.delayed(
                                          const Duration(milliseconds: 500),
                                        );
                                      },
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        itemCount: 3,
                                        itemBuilder: (context, index) =>
                                            Padding(
                                          padding: EdgeInsets.only(
                                              bottom: 20 * heightScale),
                                          child:
                                              const OrderCardSkeleton(),
                                        ),
                                      ),
                                    );
                                  }

                                  // ─ Extract orders from either state ─
                                  List<OrderModel>? orders;
                                  if (state is OrderStateLoaded) {
                                    orders = state.orders;
                                  } else if (state is OrderStateSuccess &&
                                      state.currentOrders != null) {
                                    orders = state.currentOrders;
                                  }

                                  if (orders != null) {
                                    final activeOrders = orders
                                        .where((o) => o.status.isActive)
                                        .toList();

                                    if (activeOrders.isEmpty) {
                                      return Padding(
                                        padding: EdgeInsets.all(
                                            40 * widthScale),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.receipt_long,
                                                color: AppColor.orange,
                                                size: 60 * widthScale,
                                              ),
                                              SizedBox(
                                                  height: 20 * heightScale),
                                              Text(
                                                'No active orders',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: AppColor.textDark,
                                                  fontSize:
                                                      20 * widthScale,
                                                  fontFamily:
                                                      'League Spartan',
                                                  fontWeight:
                                                      FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(
                                                  height: 8 * heightScale),
                                              Text(
                                                'New orders will appear here',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: AppColor.gray,
                                                  fontSize:
                                                      14 * widthScale,
                                                  fontFamily:
                                                      'League Spartan',
                                                  fontWeight:
                                                      FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: activeOrders.length,
                                      itemBuilder: (context, index) {
                                        final order = activeOrders[index];
                                        return Padding(
                                          padding: EdgeInsets.only(
                                              bottom: 20 * heightScale),
                                          child: _buildOrderCard(order),
                                        );
                                      },
                                    );
                                  }

                                  // ─ Error ─
                                  if (state is OrderStateError) {
                                    return Padding(
                                      padding: EdgeInsets.all(
                                          40 * widthScale),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                              size: 60 * widthScale,
                                            ),
                                            SizedBox(
                                                height: 20 * heightScale),
                                            Padding(
                                              padding:
                                                  EdgeInsets.symmetric(
                                                      horizontal:
                                                          40 * widthScale),
                                              child: Text(
                                                state.message,
                                                textAlign:
                                                    TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize:
                                                      16 * widthScale,
                                                  fontFamily:
                                                      'League Spartan',
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                                height: 20 * heightScale),
                                            GestureDetector(
                                              onTap: _fetchRestaurant,
                                              child: Container(
                                                padding:
                                                    EdgeInsets.symmetric(
                                                  horizontal:
                                                      24 * widthScale,
                                                  vertical:
                                                      10 * heightScale,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColor.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          30),
                                                ),
                                                child: Text(
                                                  'Retry',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        16 * widthScale,
                                                    fontFamily:
                                                        'League Spartan',
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  return const SizedBox.shrink();
                                },
                              ),
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
      ),
    );
  }

  // ============================================================
  // ORDER CARD — tap opens detail page, no inline actions
  // ============================================================
  Widget _buildOrderCard(OrderModel order) {
    final itemName =
        order.items.isNotEmpty ? order.items.first.name : 'Unknown Item';
    final quantity =
        order.items.isNotEmpty ? '${order.items.first.quantity}X' : '1X';

    return OrderCard(
      itemName: itemName,
      quantity: quantity,
      customerName: order.customerName,
      customerPhoneNumber: order.customerPhone ?? '',
      customerEmail: order.customerEmail,
      orderNumber: order.id.length >= 4
          ? order.id.substring(order.id.length - 4).toUpperCase()
          : order.id.toUpperCase(),
      createdAt: order.createdAt,
      actionLabel: 'View order',
      onReportIssue: order.status.isActive
          ? () => _openReportIssueSheet(order)
          : null,
      onTap: () {
        Navigator.push(
          context,
          fadeSlideRoute(
            RestaurantOrderDetailView(
              orderId: order.id,
              initialOrder: order,
            ),
          ),
        );
      },
      onReject: null,
      onAction: null,
    );
  }
}