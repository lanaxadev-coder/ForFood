// ============================================================
// USER HOME VIEW — RESPONSIVE & USING COMBINED STATE
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:geolocator/geolocator.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/hight_demand_card.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/core/widgets/rectangle_indicator.dart';
import 'package:forfood/core/widgets/restaurant_card.dart';
import 'package:forfood/core/widgets/skeleton_loader.dart';

import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/cart/cart_bloc.dart';
import 'package:forfood/service/cart/cart_state.dart';
import 'package:forfood/service/location/location_service.dart';
import 'package:forfood/service/notification/notification_bloc.dart';
import 'package:forfood/service/notification/notification_event.dart';
import 'package:forfood/service/notification/notification_state.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_bloc.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_event.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_state.dart';

import 'package:forfood/utilities/page_transition.dart';

import 'package:forfood/view/user/search_screen.dart';
import 'package:forfood/view/user/retaurant_detail_screen.dart';
import 'package:forfood/view/user/see_more_recomendation.dart';
import 'package:forfood/view/user/hight_demand_view.dart';

import 'package:forfood/core/widgets/your_usual_card.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/order/order_bloc.dart';
import 'package:forfood/service/order/order_event.dart';
import 'package:forfood/service/order/order_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DrawerType { profile, cart, notifications }

class UserHomeView extends StatefulWidget {
  const UserHomeView({super.key});

  @override
  State<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<UserHomeView> {
  int _currentIndex = 0;

  // Recommendations scroll + dots
  int _recommendationIndex = 0;
  final ScrollController _recommendationScrollController = ScrollController();

  // High demands scroll + dots
  int _highDemandIndex = 0;
  final ScrollController _highDemandScrollController = ScrollController();

  bool _showFirstTimeHint = false;
  OverlayEntry? _hintOverlay;

  DrawerType _activeDrawer = DrawerType.profile;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double? _userLatitude;
  double? _userLongitude;
  bool _showLocationBanner = false;

  @override
  void initState() {
    super.initState();
    _recommendationScrollController.addListener(_onRecommendationScroll);
    _highDemandScrollController.addListener(_onHighDemandScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationOnOpen();
      _maybeShowFirstTimeHint();
      _fetchUserOrders();
      _fetchNotifications();
    });
  }

  @override
  void dispose() {
    _recommendationScrollController
        .removeListener(_onRecommendationScroll);
    _recommendationScrollController.dispose();

    _highDemandScrollController.removeListener(_onHighDemandScroll);
    _highDemandScrollController.dispose();

    _hintOverlay?.remove();
    super.dispose();
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================
  void _fetchNotifications() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<NotificationBloc>().add(
            NotificationEventFetch(recipientId: authState.user.id),
          );
    }
  }

  // ============================================================
  // SCROLL → DOTS
  // ============================================================
  void _onRecommendationScroll() {
    if (!_recommendationScrollController.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final cardSlot = 335 * (screenWidth / 393);

    final offset = _recommendationScrollController.offset;
    final newIndex = (offset / cardSlot).round();

    if (newIndex != _recommendationIndex) {
      setState(() => _recommendationIndex = newIndex);
    }
  }

  void _onHighDemandScroll() {
    if (!_highDemandScrollController.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final cardSlot = 175 * (screenWidth / 393);

    final offset = _highDemandScrollController.offset;
    final newIndex = (offset / cardSlot).round();

    if (newIndex != _highDemandIndex) {
      setState(() => _highDemandIndex = newIndex);
    }
  }

  // ============================================================
  // PERMISSION FLOW
  // ============================================================
  Future<void> _requestLocationOnOpen() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() => _showLocationBanner = true);
      _showEnableLocationSheet(context, isServiceOff: true);
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() => _showLocationBanner = true);
      _showEnableLocationSheet(context, isServiceOff: false);
      return;
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return;
      setState(() => _showLocationBanner = true);
      return;
    }

    _checkLocationAndFetch();
  }

  // ============================================================
  // FIRST-TIME HINT
  // ============================================================
  Future<void> _maybeShowFirstTimeHint() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenHint = prefs.getBool('seen_search_hint') ?? false;

    if (hasSeenHint) return;
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showFirstTimeHint = true);
      _showHintOverlay();
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) _dismissFirstTimeHint();
      });
    });
  }

  void _showHintOverlay() {
    _hintOverlay?.remove();
    _hintOverlay = OverlayEntry(
      builder: (overlayContext) {
        final screenWidth = MediaQuery.of(overlayContext).size.width;
        final screenHeight = MediaQuery.of(overlayContext).size.height;
        final widthScale = screenWidth / 393;
        final heightScale = screenHeight / 852;

        return Positioned(
          top: 100 * heightScale,
          left: 16 * widthScale,
          right: 16 * widthScale,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismissFirstTimeHint,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * widthScale,
                  vertical: 12 * heightScale,
                ),
                decoration: BoxDecoration(
                  color: AppColor.yellow,
                  borderRadius: BorderRadius.circular(14 * widthScale),
                  border: Border.all(color: AppColor.orange, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.orange.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      '👋',
                      style: TextStyle(fontSize: 20 * widthScale),
                    ),
                    SizedBox(width: 10 * widthScale),
                    Expanded(
                      child: Text(
                        'Tap the search bar to find food by craving and budget',
                        style: TextStyle(
                          color: AppColor.textDark,
                          fontSize: 13 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_hintOverlay!);
  }

  void _dismissFirstTimeHint() {
    _hintOverlay?.remove();
    _hintOverlay = null;
    if (mounted) {
      setState(() => _showFirstTimeHint = false);
    }
    _markHintAsSeen();
  }

  Future<void> _markHintAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_search_hint', true);
  }

  // ============================================================
  // CUSTOM DIALOG
  // ============================================================
  void _showEnableLocationSheet(BuildContext context,
      {required bool isServiceOff}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColor.nearWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off,
              color: AppColor.orange,
              size: 50,
            ),
            const SizedBox(height: 16),
            Text(
              isServiceOff
                  ? 'Location is turned off'
                  : 'Location permission needed',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColor.textDark,
                fontSize: 20,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isServiceOff
                  ? 'Please enable GPS on your device so we can show nearby restaurants.'
                  : 'ForFood needs location access to show restaurants near you. Enable it in app settings.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColor.gray,
                fontSize: 14,
                fontFamily: 'League Spartan',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDECF),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'Not now',
                        style: TextStyle(
                          color: AppColor.orange,
                          fontSize: 16,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final service = LocationService();
                      if (isServiceOff) {
                        await service.openLocationSettings();
                      } else {
                        await service.openAppSettings();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColor.orange,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        isServiceOff ? 'Open GPS' : 'Open Settings',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkLocationAndFetch() async {
    final locationService = LocationService();
    final position = await locationService.getCurrentPosition();
    if (!mounted) return;

    if (position != null) {
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _showLocationBanner = false;
      });
    } else {
      setState(() {
        _showLocationBanner = true;
      });
    }

    _fetchRestaurants();
  }

  void _fetchRestaurants() {
    context.read<RestaurantListBloc>().add(
          RestaurantListEventFetchRecommendations(
            userLatitude: _userLatitude,
            userLongitude: _userLongitude,
          ),
        );
    context.read<RestaurantListBloc>().add(
          RestaurantListEventFetchHighDemands(
            userLatitude: _userLatitude,
            userLongitude: _userLongitude,
          ),
        );
  }

  void _fetchUserOrders() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<OrderBloc>().add(
            OrderEventFetchUserOrders(userId: authState.user.id),
          );
    }
  }

  // ============================================================
  // "YOUR USUAL"
  // ============================================================
  String _orderSignature(OrderModel order) {
    final items = order.items
        .map((i) => '${i.menuItemId}:${i.quantity}')
        .toList()
      ..sort();
    return '${order.restaurantId}|${items.join(",")}';
  }

  OrderModel? _findUsualOrder(List<OrderModel> orders) {
    if (orders.isEmpty) return null;

    final groups = <String, List<OrderModel>>{};
    for (final order in orders) {
      if (order.status == OrderStatus.cancelled ||
          order.status == OrderStatus.rejected) {
        continue;
      }
      final sig = _orderSignature(order);
      groups.putIfAbsent(sig, () => []).add(order);
    }

    final repeated =
        groups.entries.where((e) => e.value.length >= 2).toList();

    if (repeated.isEmpty) return null;

    repeated.sort((a, b) {
      final byCount = b.value.length.compareTo(a.value.length);
      if (byCount != 0) return byCount;
      final aLatest = a.value
          .map((o) => o.createdAt)
          .reduce((x, y) => x.isAfter(y) ? x : y);
      final bLatest = b.value
          .map((o) => o.createdAt)
          .reduce((x, y) => x.isAfter(y) ? x : y);
      return bLatest.compareTo(aLatest);
    });

    final topGroup = List<OrderModel>.from(repeated.first.value)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return topGroup.first;
  }

  void _handleOrderAgain(OrderModel order) {
    context.read<OrderBloc>().add(
          OrderEventReorderItems(originalOrder: order),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${order.items.length} item${order.items.length == 1 ? '' : 's'} added to cart',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleEnableLocation() async {
    final locationService = LocationService();
    final permission = await locationService.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      await locationService.openAppSettings();
    } else {
      await locationService.requestPermission();
    }

    await _checkLocationAndFetch();
  }

  void _openProfileDrawer() {
    setState(() => _activeDrawer = DrawerType.profile);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _openCartDrawer() {
    setState(() => _activeDrawer = DrawerType.cart);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _openNotificationDrawer() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<NotificationBloc>().add(
            NotificationEventFetch(recipientId: authState.user.id),
          );
    }
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

      _openCartDrawer();
      break;
    case 4:
          setState(() => _currentIndex = index);   // ✅ highlight

      _openProfileDrawer();
      break;
  }
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    String userName = 'Guest';
    String userEmail = 'guest@email.com';
    String profileImageUrl = '';

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      userName = authState.user.fullName;
      userEmail = authState.user.email;
      profileImageUrl = authState.user.profileImageUrl ?? '';
    }

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildActiveDrawer(userName, userEmail, profileImageUrl),
      backgroundColor: AppColor.yellow,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * widthScale,
                vertical: 8 * heightScale,
              ),
              child: Column(
                children: [
                  SizedBox(height: 16 * heightScale),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              fadeSlideRoute(const SearchView()),
                            );
                          },
                          child: Container(
                            height: 28 * heightScale,
                            padding: EdgeInsets.symmetric(
                              horizontal: 5 * widthScale,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '   Search..',
                                  style: TextStyle(
                                    color: const Color(0xFF676767),
                                    fontSize: 13 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 24 * widthScale,
                                  height: 24 * heightScale,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE95322),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/searchFilter.svg',
                                    width: 16 * widthScale,
                                    height: 16 * heightScale,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * widthScale),

                      // ✅ Notification icon — red bubble only when count > 0
                      BlocBuilder<NotificationBloc, NotificationState>(
                        builder: (context, notificationState) {
                          final unreadCount =
                              notificationState is NotificationStateLoaded
                                  ? notificationState.unreadCount
                                  : 0;

                          return _buildHeaderIcon(
                            onTap: _openNotificationDrawer,
                            icon: 'assets/icons/Notificationicon.svg',
                            badge: unreadCount == 0
                                ? null
                                : _buildRedBadge(
                                    count: unreadCount,
                                    widthScale: widthScale,
                                  ),
                          );
                        },
                      ),

                      SizedBox(width: 8 * widthScale),

                      // ✅ Cart icon — red bubble only when count > 0
                      BlocBuilder<CartBloc, CartState>(
                        builder: (context, cartState) {
                          final itemCount = cartState is CartStateLoaded
                              ? cartState.items.length
                              : 0;

                          return _buildHeaderIcon(
                            onTap: _openCartDrawer,
                            icon: 'assets/icons/carttt.svg',
                            badge: itemCount == 0
                                ? null
                                : _buildRedBadge(
                                    count: itemCount,
                                    widthScale: widthScale,
                                  ),
                          );
                        },
                      ),

                      SizedBox(width: 8 * widthScale),
                      _buildHeaderIcon(
                        onTap: _openProfileDrawer,
                        icon: 'assets/icons/userProfile.svg',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // GREETING
            Padding(
              padding: EdgeInsets.only(left: 20 * widthScale),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning',
                      style: TextStyle(
                        color: const Color(0xFFF8F8F8),
                        fontSize: 30 * widthScale,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '"Find food that fits your budget"',
                      style: TextStyle(
                        color: const Color(0xFFE95322),
                        fontSize: 13 * widthScale,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // LOCATION BANNER
            if (_showLocationBanner)
              Padding(
                padding: EdgeInsets.only(
                  left: 30 * widthScale,
                  right: 2 * widthScale,
                  top: 6 * heightScale,
                  bottom: 3 * heightScale,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _handleEnableLocation,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14 * widthScale,
                          vertical: 6 * heightScale,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColor.orange,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 6 * widthScale),
                            Text(
                              'Enable location  >',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 14 * heightScale),

            // SCROLLABLE CONTENT
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColor.nearWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: RefreshIndicator(
                  color: AppColor.orange,
                  onRefresh: () async {
                    _checkLocationAndFetch();
                  },
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: 30 * heightScale,
                      left: 15 * widthScale,
                      right: 15 * widthScale,
                      bottom: 0,
                    ),
                    children: [
                      SizedBox(height: 20 * heightScale),

                      // ===================== RECOMMENDATIONS =====================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recommendation',
                            style: TextStyle(
                              color: const Color(0xFF391713),
                              fontSize: 18 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                fadeSlideRoute(
                                    const RecommendationListView()),
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  'View All ',
                                  style: TextStyle(
                                    color: const Color(0xFFE95322),
                                    fontSize: 12 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SvgPicture.asset(
                                  'assets/icons/NexticonArrow.svg',
                                  width: 15 * widthScale,
                                  height: 15 * heightScale,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30 * heightScale),

                      BlocBuilder<RestaurantListBloc, RestaurantListState>(
                        builder: (context, state) {
                          if (state.isLoadingRecommendations) {
                            return Column(
                              children: [
                                SizedBox(
                                  height: 200 * heightScale,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 3,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 15 * widthScale),
                                    separatorBuilder: (_, __) =>
                                        SizedBox(width: 12 * widthScale),
                                    itemBuilder: (context, index) =>
                                        const RestaurantCardSkeleton(),
                                  ),
                                ),
                                SizedBox(height: 10 * heightScale),
                                const Center(
                                  child: DotsIndicator(
                                    activeIndex: 0,
                                    count: 3,
                                  ),
                                ),
                              ],
                            );
                          }

                          final recommendations = state.recommendations;

                          if (recommendations.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 24 * heightScale),
                              child: Center(
                                child: Text(
                                  'No restaurants yet',
                                  style: TextStyle(
                                    color: AppColor.gray,
                                    fontSize: 14 * widthScale,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: [
                              SizedBox(
                                height: 200 * heightScale,
                                child: ListView.separated(
                                  controller: _recommendationScrollController,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: recommendations.length,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 15 * widthScale),
                                  separatorBuilder: (_, __) =>
                                      SizedBox(width: 12 * widthScale),
                                  itemBuilder: (context, index) {
                                    final item = recommendations[index];
                                    return RestaurantCard(
                                      imageUrl: item
                                              .restaurant.profileImageUrl ??
                                          '',
                                      distance:
                                          '${item.distanceKm.toStringAsFixed(1)} km',
                                      name: item.restaurant.name,
                                      rating:
                                          item.restaurant.rating.round(),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          fadeSlideRoute(
                                              RestaurantDetailView(
                                            restaurantName:
                                                item.restaurant.name,
                                            restaurantId:
                                                item.restaurant.id,
                                          )),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 10 * heightScale),
                              Center(
                                child: DotsIndicator(
                                  activeIndex: _recommendationIndex,
                                  count: recommendations.length,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: 40 * heightScale),
                      Padding(
                        padding: EdgeInsets.all(10 * widthScale),
                        child: Container(
                          height: 1,
                          color: AppColor.divider,
                        ),
                      ),
                      SizedBox(height: 40 * heightScale),

                      // ===================== YOUR USUAL =====================
                      BlocBuilder<OrderBloc, OrderState>(
                        builder: (context, orderState) {
                          List<OrderModel>? orders;
                          if (orderState is OrderStateLoaded) {
                            orders = orderState.orders;
                          } else if (orderState is OrderStateSuccess &&
                              orderState.currentOrders != null) {
                            orders = orderState.currentOrders;
                          }

                          if (orders == null) return const SizedBox.shrink();

                          final usual = _findUsualOrder(orders);
                          if (usual == null) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your usual',
                                style: TextStyle(
                                  color: const Color(0xFF391713),
                                  fontSize: 18 * widthScale,
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 16 * heightScale),
                              YourUsualCard(
                                order: usual,
                                onOrderAgain: () =>
                                    _handleOrderAgain(usual),
                              ),
                              SizedBox(height: 40 * heightScale),
                              Padding(
                                padding: EdgeInsets.all(10 * widthScale),
                                child: Container(
                                    height: 1, color: AppColor.divider),
                              ),
                              SizedBox(height: 40 * heightScale),
                            ],
                          );
                        },
                      ),

                      // ===================== HIGH DEMANDS =====================
                      BlocBuilder<RestaurantListBloc, RestaurantListState>(
                        builder: (context, state) {
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Hight demands',
                                    style: TextStyle(
                                      color: const Color(0xFF391713),
                                      fontSize: 18 * widthScale,
                                      fontFamily: 'League Spartan',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        fadeSlideRoute(
                                            const HighDemandsView()),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          'View All ',
                                          style: TextStyle(
                                            color: const Color(0xFFE95322),
                                            fontSize: 12 * widthScale,
                                            fontFamily: 'League Spartan',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SvgPicture.asset(
                                          'assets/icons/NexticonArrow.svg',
                                          width: 15 * widthScale,
                                          height: 15 * heightScale,
                                          fit: BoxFit.contain,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 40 * heightScale),

                              if (state.isLoadingHighDemands)
                                Column(
                                  children: [
                                    SizedBox(
                                      height: 140 * heightScale,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: 3,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 15 * widthScale),
                                        separatorBuilder: (_, __) =>
                                            SizedBox(
                                                width: 12 * widthScale),
                                        itemBuilder: (context, index) =>
                                            const HighDemandCardSkeleton(),
                                      ),
                                    ),
                                    SizedBox(height: 10 * heightScale),
                                    const Center(
                                      child: DotsIndicator(
                                        activeIndex: 0,
                                        count: 3,
                                      ),
                                    ),
                                  ],
                                )
                              else if (state.highDemands.isNotEmpty)
                                Column(
                                  children: [
                                    SizedBox(
                                      height: 140 * heightScale,
                                      child: ListView.separated(
                                        controller:
                                            _highDemandScrollController,
                                        scrollDirection: Axis.horizontal,
                                        itemCount:
                                            state.highDemands.length,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 15 * widthScale),
                                        separatorBuilder: (_, __) =>
                                            SizedBox(
                                                width: 12 * widthScale),
                                        itemBuilder: (context, index) {
                                          final dish =
                                              state.highDemands[index];
                                          return HighDemandCard(
                                            imageUrl: dish
                                                    .menuItem.imageUrl ??
                                                '',
                                            rating: dish.restaurant.rating
                                                .toString(),
                                            price:
                                                '\$${dish.menuItem.price.toStringAsFixed(0)}',
                                            restaurantName:
                                                dish.restaurant.name,
                                            dishName: dish.menuItem.name,
                                            distanceKm: dish.distanceKm,
                                            orderCount:
                                                dish.menuItem.orderCount,
                                            isDelivery: dish.restaurant
                                                .isDeliveryEnabled,
                                            onTap: () {
                                              Navigator.of(context).push(
                                                fadeSlideRoute(
                                                    RestaurantDetailView(
                                                  restaurantName:
                                                      dish.restaurant.name,
                                                  restaurantId:
                                                      dish.restaurant.id,
                                                )),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 10 * heightScale),
                                    Center(
                                      child: DotsIndicator(
                                        activeIndex: _highDemandIndex,
                                        count: state.highDemands.length,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 20 * heightScale),
                                  child: Center(
                                    child: Text(
                                      'No items yet',
                                      style: TextStyle(
                                        color: AppColor.gray,
                                        fontSize: 14 * widthScale,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: 40 * heightScale),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColor.nearWhite,
        child: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _handleBottomNavTap,
        ),
      ),
    );
  }

  // ============================================================
  // HEADER ICON — icon box; badge is now passed pre-positioned
  // ============================================================
  Widget _buildHeaderIcon({
    required VoidCallback onTap,
    required String icon,
    Widget? badge,
  }) {
    final widthScale = MediaQuery.of(context).size.width / 393;
    final heightScale = MediaQuery.of(context).size.height / 852;

    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 28 * widthScale,
            height: 28 * heightScale,
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: SvgPicture.asset(
                icon,
                width: 18 * widthScale,
                height: 18 * heightScale,
              ),
            ),
          ),
          // ✅ Badge is caller-provided, already positioned. If null,
          //    nothing renders — no empty red dot.
          if (badge != null) badge,
        ],
      ),
    );
  }

  // ============================================================
  // RED BADGE — helper so callers don't repeat the styling
  // ============================================================
  Widget _buildRedBadge({
    required int count,
    required double widthScale,
  }) {
    return Positioned(
      top: -2,
      right: -2,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
        child: Text(
          '$count',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9 * widthScale,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveDrawer(
      String userName, String userEmail, String profileImageUrl) {
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
}