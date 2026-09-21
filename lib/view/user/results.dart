// ============================================================
// RESULTS VIEW — FIXED DRAWER + MAP + BOTTOM NAV + RESPONSIVE
// + Add to Cart on each result card
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/widgets/skeleton_loader.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/core/widgets/location_map_view.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/core/widgets/result_card.dart';

import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/cart/cart_bloc.dart';
import 'package:forfood/service/cart/cart_event.dart';
import 'package:forfood/service/cart/cart_state.dart';
import 'package:forfood/service/search/search_bloc.dart';
import 'package:forfood/service/search/search_state.dart';
import 'package:forfood/utilities/haptic_feedback.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/user/retaurant_detail_screen.dart';
import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class ResultsView extends StatefulWidget {
  final String craving;
  final String maxBudget;
  final String location;

  const ResultsView({
    super.key,
    required this.craving,
    required this.maxBudget,
    required this.location,
  });

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  int _currentIndex = 1;

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
        _openCartDrawer();
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

                Positioned(
                  left: 140 * widthScale,
                  top: 76 * heightScale,
                  child: Text(
                    'Results',
                    style: TextStyle(
                      color: AppColor.nearWhite,
                      fontSize: 30 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  top: 170 * heightScale,
                  bottom: 0,
                  child: BlocBuilder<SearchBloc, SearchState>(
                    builder: (context, searchState) {
                      // ─────────── LOADING ───────────
                      if (searchState is SearchStateLoading) {
                        return ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16 * widthScale,
                            vertical: 12 * heightScale,
                          ),
                          itemCount: 4,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 16 * heightScale),
                          itemBuilder: (context, index) =>
                              const ResultCardSkeleton(),
                        );
                      }

                      // ─────────── LOADED ───────────
                      if (searchState is SearchStateLoaded) {
                        final results = searchState.results;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 20 * widthScale),
                              child: Text(
                                '${results.length} places found',
                                style: TextStyle(
                                  color: AppColor.textDark,
                                  fontSize: 14 * widthScale,
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),

                            Expanded(
                              child: RefreshIndicator(
                                color: AppColor.orange,
                                onRefresh: () async {
                                  await Future.delayed(
                                    const Duration(milliseconds: 500),
                                  );
                                },
                                child: ListView.separated(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16 * widthScale,
                                    vertical: 12 * heightScale,
                                  ),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: results.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(height: 16 * heightScale),

                                  // ─────────── ITEM BUILDER ───────────
                                  itemBuilder: (context, index) {
                                    final result = results[index];

                                    return ResultCard(
                                      imageUrl:
                                          result.cheapestItem.imageUrl ??
                                              'https://placehold.co/90x110',
                                      name: result.restaurant.name,
                                      dishPreview:
                                          result.cheapestItem.name,
                                      distance:
                                          '${result.distanceKm.toStringAsFixed(1)} km',
                                      rating: result
                                          .restaurant.rating
                                          .toStringAsFixed(1),
                                      price:
                                          '\$${result.cheapestItem.price.toStringAsFixed(0)}',
                                      mode: result.restaurant
                                              .isDeliveryEnabled
                                          ? 'Delivery'
                                          : 'Dine-in',

                                      // ── Card tap → restaurant detail ──
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          fadeSlideRoute(
                                            RestaurantDetailView(
                                              restaurantName:
                                                  result.restaurant.name,
                                              restaurantId:
                                                  result.restaurant.id,
                                            ),
                                          ),
                                        );
                                      },

                                      // ── View All → restaurant detail ──
                                      onViewAll: () {
                                        Navigator.push(
                                          context,
                                          fadeSlideRoute(
                                            RestaurantDetailView(
                                              restaurantName:
                                                  result.restaurant.name,
                                              restaurantId:
                                                  result.restaurant.id,
                                            ),
                                          ),
                                        );
                                      },

                                      // ── See in Map → location map ──
                                      onSeeInMap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => LocationMapView(
                                              title: 'Restaurant Location',
                                              destinationName:
                                                  result.restaurant.name,
                                              destinationAddress:
                                                  result.restaurant.address,
                                              destinationLatitude:
                                                  result.restaurant.latitude,
                                              destinationLongitude:
                                                  result.restaurant.longitude,
                                            ),
                                          ),
                                        );
                                      },

                                      // ── Add to Cart ──
                                      onAddToCart: () {
                                        HapticFeedbackUtil.medium();

                                        final cartState =
                                            context.read<CartBloc>().state;

                                        // Preflight: block multi-restaurant
                                        if (cartState is CartStateLoaded &&
                                            cartState.restaurantId !=
                                                result.restaurant.id) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Your cart already has items '
                                                'from another restaurant. '
                                                'Clear it first to add '
                                                '${result.cheapestItem.name}.',
                                              ),
                                              backgroundColor: AppColor.red,
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        context.read<CartBloc>().add(
                                              CartEventAddItem(
                                                item: OrderItem(
                                                  menuItemId:
                                                      result.cheapestItem.id,
                                                  name: result
                                                      .cheapestItem.name,
                                                  price: result
                                                      .cheapestItem.price,
                                                  quantity: 1,
                                                  imageUrl: result
                                                      .cheapestItem.imageUrl,
                                                  dateTime: DateTime.now(),
                                                ),
                                                restaurantId:
                                                    result.restaurant.id,
                                                restaurantName: result
                                                    .restaurant.name,
                                              ),
                                            );

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${result.cheapestItem.name} '
                                              'added to cart',
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // ─────────── EMPTY ───────────
                      if (searchState is SearchStateEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                color: AppColor.orange,
                                size: 60 * widthScale,
                              ),
                              SizedBox(height: 20 * heightScale),
                              Text(
                                'No results found',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColor.textDark,
                                  fontSize: 20 * widthScale,
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 8 * heightScale),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 40 * widthScale,
                                ),
                                child: Text(
                                  'Try increasing your budget or changing your craving',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColor.gray,
                                    fontSize: 14 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20 * heightScale),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
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
                                    'Back to Search',
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

                      // ─────────── ERROR ───────────
                      if (searchState is SearchStateError) {
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
                                  horizontal: 40 * widthScale,
                                ),
                                child: Text(
                                  searchState.message,
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
                                onTap: () => Navigator.pop(context),
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
                                    'Back to Search',
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

                      return const SizedBox.shrink();
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
    );
  }
}