// ============================================================
// RESTAURANT HOME VIEW — FIXED
// ============================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/delivery_togggle.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/menu_item_card.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/core/widgets/skeleton_loader.dart';
import 'package:forfood/core/widgets/star_rating.dart';
import 'package:forfood/core/widgets/stat_card.dart';
import 'package:forfood/core/widgets/trial_banner.dart';
import 'package:forfood/core/widgets/view_all_link.dart';

import 'package:forfood/models/notification_model.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/models/restaurant_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:forfood/service/menu/menu_bloc.dart';
import 'package:forfood/service/menu/menu_event.dart';
import 'package:forfood/service/menu/menu_state.dart';
import 'package:forfood/service/notification/notification_bloc.dart';
import 'package:forfood/service/notification/notification_event.dart';
import 'package:forfood/service/notification/notification_state.dart';
import 'package:forfood/service/order/order_bloc.dart';
import 'package:forfood/service/order/order_event.dart';
import 'package:forfood/service/order/order_state.dart';
import 'package:forfood/service/restaurant/restaurant_bloc.dart';
import 'package:forfood/service/restaurant/restaurant_event.dart';
import 'package:forfood/service/restaurant/restaurant_state.dart';
import 'package:forfood/service/subscription/trial_manager.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/restaurant/add_item_in_menu.dart';
import 'package:forfood/view/restaurant/galery.dart';
import 'package:forfood/view/restaurant/incoming_order.dart';
import 'package:forfood/view/restaurant/menu.dart';
import 'package:forfood/view/restaurant/profile.dart';
import 'package:forfood/view/restaurant/statistics_view.dart';

enum RestaurantDrawerType { profile, notifications }

class RestaurantHomeView extends StatefulWidget {
  const RestaurantHomeView({super.key});

  @override
  State<RestaurantHomeView> createState() => _RestaurantHomeViewState();
}

class _RestaurantHomeViewState extends State<RestaurantHomeView> {
  bool _isDeliveryEnabled = true;
  bool _isSavingDeliveryStatus = false;

  int _currentIndex = 0;
  RestaurantDrawerType _activeDrawer = RestaurantDrawerType.profile;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreProvider _firestoreProvider = FirestoreProvider();

  String? _restaurantId;

  StreamSubscription<List<String>>? _gallerySubscription;
  List<String> _galleryImages = [];
  bool _isGalleryLoading = true;
  Timer? _galleryTimeoutTimer;

  @override
  void initState() {
    super.initState();

    // ✅ Run after the first frame so `context.read<AuthBloc>().state`
    // is guaranteed to be AuthStateLoggedIn.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRestaurant();
      _fetchNotifications();
    });
  }

  @override
  void dispose() {
    _gallerySubscription?.cancel();
    _galleryTimeoutTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // DATA FETCHING
  // ============================================================
  void _fetchNotifications() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<NotificationBloc>().add(
            NotificationEventFetch(recipientId: authState.user.id),
          );
    }
  }

  void _fetchRestaurant() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<RestaurantBloc>().add(
            RestaurantEventFetchByOwnerId(ownerId: authState.user.id),
          );
    }
  }

  void _fetchMenuAndOrders(String restaurantId) {
    _restaurantId = restaurantId;
    context.read<MenuBloc>().add(
          MenuEventFetchByRestaurant(restaurantId: restaurantId),
        );
    context.read<OrderBloc>().add(
          OrderEventFetchRestaurantOrders(restaurantId: restaurantId),
        );
    _fetchGallery(restaurantId);
  }

  void _fetchGallery(String restaurantId) {
    _gallerySubscription?.cancel();
    _galleryTimeoutTimer?.cancel();

    _galleryTimeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isGalleryLoading) {
        setState(() => _isGalleryLoading = false);
      }
    });

    _gallerySubscription = _firestoreProvider
        .streamGalleryImagesByRestaurantId(restaurantId)
        .listen(
      (images) {
        _galleryTimeoutTimer?.cancel();
        if (mounted) {
          setState(() {
            _galleryImages = images;
            _isGalleryLoading = false;
          });
        }
      },
      onError: (error) {
        _galleryTimeoutTimer?.cancel();
        debugPrint('Gallery stream error: $error');
        if (mounted) {
          setState(() => _isGalleryLoading = false);
        }
      },
    );
  }

  Future<void> _refreshAll() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthStateLoggedIn) return;

    context.read<RestaurantBloc>().add(
          RestaurantEventFetchByOwnerId(ownerId: authState.user.id),
        );
    context.read<NotificationBloc>().add(
          NotificationEventFetch(recipientId: authState.user.id),
        );

    if (_restaurantId != null) {
      context.read<MenuBloc>().add(
            MenuEventFetchByRestaurant(restaurantId: _restaurantId!),
          );
      context.read<OrderBloc>().add(
            OrderEventFetchRestaurantOrders(restaurantId: _restaurantId!),
          );
      _fetchGallery(_restaurantId!);
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ============================================================
  // DELIVERY TOGGLE
  // ============================================================
  Future<void> _handleDeliveryToggle(bool newValue) async {
    if (_isSavingDeliveryStatus || _restaurantId == null) return;

    setState(() {
      _isDeliveryEnabled = newValue;
      _isSavingDeliveryStatus = true;
    });

    try {
      final restaurant =
          await _firestoreProvider.getRestaurantById(_restaurantId!);

      final updatedRestaurant = restaurant.copyWith(
        isDeliveryEnabled: newValue,
      );
      await _firestoreProvider.updateRestaurant(updatedRestaurant);

      if (!newValue) {
        await _cancelPendingDeliveryOrders(_restaurantId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newValue
                  ? 'Delivery enabled successfully'
                  : 'Delivery disabled. Pending delivery orders were cancelled.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeliveryEnabled = !newValue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update delivery status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingDeliveryStatus = false);
      }
    }
  }

  Future<void> _cancelPendingDeliveryOrders(String restaurantId) async {
    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.orders)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: OrderStatus.pending.name)
          .where('deliveryMethod', isEqualTo: DeliveryMethod.delivery.name)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in ordersSnapshot.docs) {
        batch.update(doc.reference, {
          'status': OrderStatus.cancelled.name,
          'cancellationReason': 'Restaurant stopped delivering',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final orderData = doc.data();
        final userId = orderData['userId'] as String?;
        if (userId != null) {
          final notification = NotificationModel(
            id: '',
            recipientId: userId,
            type: NotificationType.orderCancelled,
            title: 'Order Cancelled',
            message:
                'Your delivery order was cancelled because the restaurant stopped delivering.',
            orderId: doc.id,
            isRead: false,
            createdAt: DateTime.now(),
          );
          await _firestoreProvider.createNotification(notification);
        }
      }

      await batch.commit();
    } catch (e) {
      throw FirestoreOperationException(
          'Failed to cancel pending delivery orders: $e');
    }
  }

  // ============================================================
  // DRAWERS
  // ============================================================
  void _openProfileDrawer() {
    setState(() => _activeDrawer = RestaurantDrawerType.profile);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _openNotificationDrawer() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<NotificationBloc>().add(
            NotificationEventFetch(recipientId: authState.user.id),
          );
    }
    setState(() => _activeDrawer = RestaurantDrawerType.notifications);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  // ============================================================
  // BOTTOM NAV
  // ============================================================
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
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<RestaurantBloc, RestaurantState>(
          builder: (context, restaurantState) {
            String restaurantName = '';
            String restaurantEmail = '';
            String? profileImageUrl;

            if (authState is AuthStateLoggedIn) {
              restaurantName = authState.user.fullName;
              restaurantEmail = authState.user.email;
              profileImageUrl = authState.user.profileImageUrl;
            }

            double restaurantRating = 0.0;

            if (restaurantState is RestaurantStateLoaded) {
              restaurantName = restaurantState.restaurant.name;
              restaurantRating = restaurantState.restaurant.rating;

              if (!_isSavingDeliveryStatus) {
                _isDeliveryEnabled =
                    restaurantState.restaurant.isDeliveryEnabled;
              }

              if (_restaurantId != restaurantState.restaurant.id) {
                _fetchMenuAndOrders(restaurantState.restaurant.id);
              }
            }

            return Scaffold(
              key: _scaffoldKey,
              endDrawer: _buildActiveDrawer(
                restaurantName: restaurantName,
                restaurantEmail: restaurantEmail,
                profileImageUrl: profileImageUrl,
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

                    // ==================================================
                    // NOTIFICATION ICON + BADGE (only shows when > 0)
                    // ==================================================
                    Positioned(
                      top: 15 * heightScale,
                      right: 20 * widthScale,
                      child: InkWell(
                        onTap: _openNotificationDrawer,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 35 * widthScale,
                              height: 35 * widthScale,
                              decoration: ShapeDecoration(
                                color: AppColor.offWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(4 * widthScale),
                                child: SvgPicture.asset(
                                  'assets/icons/Notificationicon.svg',
                                  width: 20 * widthScale,
                                  height: 20 * widthScale,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            // ✅ Badge inside BlocBuilder. When count is 0,
                            //    returns null — nothing rendered, no empty
                            //    red circle.
                            BlocBuilder<NotificationBloc,
                                NotificationState>(
                              builder: (context, notificationState) {
                                final unreadCount = notificationState
                                        is NotificationStateLoaded
                                    ? notificationState.unreadCount
                                    : 0;

                                if (unreadCount == 0) {
                                  return const SizedBox.shrink();
                                }

                                return Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    constraints: const BoxConstraints(
                                        minWidth: 16, minHeight: 16),
                                    child: Text(
                                      '$unreadCount',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Profile icon
                    Positioned(
                      top: 15 * heightScale,
                      right: 65 * widthScale,
                      child: GestureDetector(
                        onTap: _openProfileDrawer,
                        child: Container(
                          width: 35 * widthScale,
                          height: 35 * widthScale,
                          decoration: BoxDecoration(
                            color: AppColor.offWhite,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/userProfile.svg',
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Restaurant name
                    Positioned(
                      top: 60 * heightScale,
                      left: 15 * widthScale,
                      right: 15 * widthScale,
                      child: Text(
                        restaurantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColor.textDark,
                          fontSize: 28 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // Welcome back
                    Positioned(
                      top: 101 * heightScale,
                      left: 31 * widthScale,
                      child: Text(
                        'Welcome back',
                        style: TextStyle(
                          color: AppColor.white,
                          fontSize: 24 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // Subtitle
                    Positioned(
                      top: 130 * heightScale,
                      left: 34 * widthScale,
                      child: Text(
                        'Start serving more customers',
                        style: TextStyle(
                          color: AppColor.orange,
                          fontSize: 13 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Content
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 168 * heightScale,
                      bottom: 0,
                      child: RefreshIndicator(
                        color: AppColor.orange,
                        onRefresh: () async {
                          await _refreshAll();
                        },
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Delivery toggle + trial banner
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15 * widthScale),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    DeliveryToggle(
                                      value: _isDeliveryEnabled,
                                      onChanged: _isSavingDeliveryStatus
                                          ? null
                                          : _handleDeliveryToggle,
                                    ),
                                    const SizedBox(width: 50),
                                    BlocBuilder<RestaurantBloc,
                                        RestaurantState>(
                                      builder: (context, restaurantState) {
                                        RestaurantModel? restaurant;
                                        if (restaurantState
                                            is RestaurantStateLoaded) {
                                          restaurant =
                                              restaurantState.restaurant;
                                        }
                                        final statusInfo =
                                            TrialManager.getTrialStatus(
                                                restaurant);
                                        return TrialBanner(
                                            statusInfo: statusInfo);
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // Star rating
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 15 * widthScale),
                                child: StarRating(
                                    rating: restaurantRating.round()),
                              ),

                              SizedBox(height: 40 * heightScale),

                              // Stats
                              BlocBuilder<RestaurantBloc, RestaurantState>(
                                builder: (context, restaurantState) {
                                  int viewsCount = 0;
                                  if (restaurantState
                                      is RestaurantStateLoaded) {
                                    viewsCount =
                                        restaurantState.restaurant.views;
                                  }

                                  return BlocBuilder<OrderBloc, OrderState>(
                                    builder: (context, orderState) {
                                      int ordersCount = 0;
                                      int completedTodayCount = 0;
                                      double todayRevenue = 0.0;
                                      int pendingCount = 0;

                                      if (orderState is OrderStateLoaded) {
                                        ordersCount =
                                            orderState.orders.length;

                                        final now = DateTime.now();
                                        final todayStart = DateTime(now.year,
                                            now.month, now.day);

                                        for (final order
                                            in orderState.orders) {
                                          if (order.status ==
                                              OrderStatus.pending) {
                                            pendingCount += 1;
                                          }
                                          if (order.status ==
                                                  OrderStatus.completed &&
                                              order.createdAt
                                                  .isAfter(todayStart)) {
                                            todayRevenue += order.total;
                                            completedTodayCount += 1;
                                          }
                                        }
                                      }

                                      return Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    15 * widthScale),
                                            child: _RevenueCard(
                                              revenue: todayRevenue,
                                              orderCount:
                                                  completedTodayCount,
                                            ),
                                          ),

                                          SizedBox(
                                              height: 16 * heightScale),

                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    fadeSlideRoute(
                                                        const OrdersView()),
                                                  );
                                                },
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    StatCard(
                                                      label: 'Orders',
                                                      value: '$ordersCount',
                                                    ),
                                                    // ✅ Only shows when
                                                    //    pendingCount > 0
                                                    if (pendingCount > 0)
                                                      Positioned(
                                                        top: -6,
                                                        right: -6,
                                                        child: Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            horizontal:
                                                                6 * widthScale,
                                                            vertical: 2,
                                                          ),
                                                          constraints:
                                                              BoxConstraints(
                                                            minWidth:
                                                                18 * widthScale,
                                                            minHeight:
                                                                18 * widthScale,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.red,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            border: Border.all(
                                                                color: Colors
                                                                    .white,
                                                                width: 1.5),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              pendingCount > 9
                                                                  ? '9+'
                                                                  : '$pendingCount',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize:
                                                                    10 *
                                                                        widthScale,
                                                                fontFamily:
                                                                    'League Spartan',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                height: 1,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                  width: 20 * widthScale),
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    fadeSlideRoute(
                                                        const StatisticsView()),
                                                  );
                                                },
                                                child: StatCard(
                                                  label: 'Views',
                                                  value: '$viewsCount',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),

                              SizedBox(height: 30 * heightScale),

                              Center(
                                child: Container(
                                  height: 0.74,
                                  width: 324 * widthScale,
                                  color: AppColor.divider,
                                ),
                              ),
                              SizedBox(height: 20 * heightScale),

                              // Menu section
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 15 * widthScale),
                                    child: Text(
                                      'Your Menu',
                                      style: TextStyle(
                                        color: AppColor.black,
                                        fontSize: 17 * widthScale,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  ViewAllLink(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        fadeSlideRoute(
                                            const MenuListView()),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 15 * widthScale),
                                ],
                              ),
                              SizedBox(height: 15 * widthScale),

                              BlocBuilder<MenuBloc, MenuState>(
                                builder: (context, menuState) {
                                  if (menuState is MenuStateLoading) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: List.generate(
                                          3,
                                          (index) => Padding(
                                            padding: EdgeInsets.only(
                                                left: 8 * widthScale),
                                            child:
                                                const MenuItemCardSkeleton(),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (menuState is MenuStateLoaded) {
                                    final menuItems = menuState.menuItems;

                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                                left: 8 * widthScale),
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  fadeSlideRoute(
                                                      const AddMenuItemView()),
                                                );
                                              },
                                              child: Container(
                                                width: 122 * widthScale,
                                                height: 148 * widthScale,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: AppColor.orange,
                                                  border: Border.all(
                                                    color: AppColor.textDark,
                                                    width: 1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          38),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                  children: [
                                                    Text(
                                                      '+',
                                                      style: TextStyle(
                                                        color:
                                                            AppColor.textDark,
                                                        fontSize:
                                                            40 * widthScale,
                                                      ),
                                                    ),
                                                    Text(
                                                      'add item',
                                                      style: TextStyle(
                                                        color:
                                                            AppColor.textDark,
                                                        fontSize:
                                                            18 * widthScale,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          ...menuItems.map((item) {
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                  left: 8 * widthScale),
                                              child: MenuItemCard(
                                                imageUrl: item.imageUrl ??
                                                    'https://picsum.photos/97/75',
                                                name: item.name,
                                                price:
                                                    '\$${item.price.toStringAsFixed(2)}',
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    fadeSlideRoute(
                                                        const MenuListView()),
                                                  );
                                                },
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  }

                                  return const SizedBox.shrink();
                                },
                              ),

                              SizedBox(height: 30 * heightScale),

                              Center(
                                child: Container(
                                  height: 0.74,
                                  width: 324 * widthScale,
                                  color: AppColor.divider,
                                ),
                              ),
                              SizedBox(height: 20 * heightScale),

                              // Gallery section
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 15 * widthScale),
                                    child: Text(
                                      'Galery',
                                      style: TextStyle(
                                        color: AppColor.black,
                                        fontSize: 18 * widthScale,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  ViewAllLink(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        fadeSlideRoute(
                                            const GalleryListView()),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 15 * widthScale),
                                ],
                              ),

                              SizedBox(height: 20 * heightScale),

                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15 * widthScale),
                                child: SizedBox(
                                  height: 230 * heightScale,
                                  child: _isGalleryLoading
                                      ? ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: 3,
                                          separatorBuilder:
                                              (context, index) => SizedBox(
                                                  width: 5 * widthScale),
                                          itemBuilder: (context, index) =>
                                              const GalleryCardSkeleton(),
                                        )
                                      : _galleryImages.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'No gallery images yet',
                                                style: TextStyle(
                                                  color: AppColor.gray,
                                                  fontSize: 14,
                                                  fontFamily:
                                                      'League Spartan',
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              scrollDirection:
                                                  Axis.horizontal,
                                              itemCount:
                                                  _galleryImages.length,
                                              itemBuilder:
                                                  (context, index) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                      right:
                                                          5 * widthScale),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            Dialog(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          child: Stack(
                                                            children: [
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20),
                                                                child: Image
                                                                    .network(
                                                                  _galleryImages[
                                                                      index],
                                                                  fit: BoxFit
                                                                      .contain,
                                                                  errorBuilder: (_,
                                                                          __,
                                                                          ___) =>
                                                                      Container(
                                                                    color: const Color(
                                                                        0xFFFFDECF),
                                                                    child: const Icon(
                                                                        Icons
                                                                            .image,
                                                                        color: AppColor
                                                                            .orange,
                                                                        size:
                                                                            60),
                                                                  ),
                                                                ),
                                                              ),
                                                              Positioned(
                                                                top: 10,
                                                                right: 10,
                                                                child:
                                                                    GestureDetector(
                                                                  onTap: () =>
                                                                      Navigator.pop(
                                                                          context),
                                                                  child:
                                                                      Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8),
                                                                    decoration:
                                                                        const BoxDecoration(
                                                                      color: Colors
                                                                          .black54,
                                                                      shape: BoxShape
                                                                          .circle,
                                                                    ),
                                                                    child: const Icon(
                                                                        Icons
                                                                            .close,
                                                                        color: Colors
                                                                            .white,
                                                                        size:
                                                                            20),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      width:
                                                          118 * widthScale,
                                                      height:
                                                          230 * heightScale,
                                                      decoration:
                                                          BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                        child: Image.network(
                                                          _galleryImages[
                                                              index],
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (_, __, ___) =>
                                                                  Container(
                                                            color: const Color(
                                                                0xFFFFDECF),
                                                            child: const Icon(
                                                              Icons.image,
                                                              color: AppColor
                                                                  .orange,
                                                              size: 40,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                ),
                              ),
                              SizedBox(height: 30 * heightScale),
                            ],
                          ),
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

  Widget _buildActiveDrawer({
    required String restaurantName,
    required String restaurantEmail,
    String? profileImageUrl,
  }) {
    switch (_activeDrawer) {
      case RestaurantDrawerType.profile:
        return buildRestaurantDrawer(
          name: restaurantName,
          email: restaurantEmail,
          profileImageUrl: profileImageUrl,
        );
      case RestaurantDrawerType.notifications:
        return const NotificationDrawer();
    }
  }
}

// ============================================================
// REVENUE CARD
// ============================================================
class _RevenueCard extends StatelessWidget {
  final double revenue;
  final int orderCount;

  const _RevenueCard({
    required this.revenue,
    required this.orderCount,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20 * widthScale,
        vertical: 16 * widthScale,
      ),
      decoration: BoxDecoration(
        color: AppColor.orange,
        borderRadius: BorderRadius.circular(24 * widthScale),
        boxShadow: [
          BoxShadow(
            color: AppColor.orange.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: Colors.white.withOpacity(0.85),
                size: 18 * widthScale,
              ),
              SizedBox(width: 4 * widthScale),
              Text(
                "Today's revenue",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13 * widthScale,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 6 * widthScale),
          Text(
            '\$${revenue.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38 * widthScale,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          SizedBox(height: 2 * widthScale),
          Text(
            orderCount == 0
                ? 'No completed orders yet today'
                : 'from $orderCount completed order${orderCount == 1 ? '' : 's'}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12 * widthScale,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}