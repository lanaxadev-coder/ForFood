// ============================================================
// HIGH DEMANDS VIEW — PRODUCTION READY (COMBINED STATE)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/location_map_view.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/hight_demand_card_list.dart';
import 'package:forfood/core/widgets/skeleton_loader.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_bloc.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_event.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_state.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/user/retaurant_detail_screen.dart';
import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class HighDemandsView extends StatefulWidget {
  const HighDemandsView({super.key});

  @override
  State<HighDemandsView> createState() => _HighDemandsViewState();
}

class _HighDemandsViewState extends State<HighDemandsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  // ✅ Which drawer to show
  DrawerType _activeDrawer = DrawerType.profile;

  @override
  void initState() {
    super.initState();
    _fetchHighDemands();
  }

  void _fetchHighDemands() {
    context.read<RestaurantListBloc>().add(
          const RestaurantListEventFetchHighDemands(),
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
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          tabRoute(const UserHomeView()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          tabRoute(const SearchView()),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          tabRoute(const ChatInboxView()),
        );
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
                  left: 80 * widthScale,
                  top: 78 * heightScale,
                  child: Text(
                    'Hight Demands ',
                    style: TextStyle(
                      color: AppColor.textDark,
                      fontSize: 22 * widthScale,
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
                  child:
                      BlocBuilder<RestaurantListBloc, RestaurantListState>(
                    builder: (context, state) {
                      if (state.isLoadingHighDemands) {
                        return RefreshIndicator(
                          color: AppColor.orange,
                          onRefresh: () async {
                            _fetchHighDemands();
                            await Future.delayed(
                                const Duration(milliseconds: 500));
                          },
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20 * widthScale,
                              vertical: 16 * heightScale,
                            ),
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            itemCount: 4,
                            separatorBuilder: (_, __) => Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12 * heightScale),
                              child: const Divider(
                                color: Color(0xFFFFD7C6),
                                thickness: 1,
                              ),
                            ),
                            itemBuilder: (context, index) =>
                                const HighDemandCardSkeleton(),
                          ),
                        );
                      }

                      if (state.error != null) {
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
                                  state.error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16 * widthScale,
                                    fontFamily: 'League Spartan',
                                  ),
                                ),
                              ),
                              SizedBox(height: 20 * heightScale),
                              GestureDetector(
                                onTap: _fetchHighDemands,
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

                      if (state.highDemands.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: AppColor.orange,
                                size: 60 * widthScale,
                              ),
                              SizedBox(height: 20 * heightScale),
                              Text(
                                'No high demand items yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColor.textDark,
                                  fontSize: 20 * widthScale,
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 8 * heightScale),
                              Text(
                                'Popular dishes will appear here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColor.gray,
                                  fontSize: 14 * widthScale,
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              SizedBox(height: 20 * heightScale),
                              GestureDetector(
                                onTap: _fetchHighDemands,
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
                                    'Refresh',
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

                      return RefreshIndicator(
                        color: AppColor.orange,
                        onRefresh: () async {
                          _fetchHighDemands();
                          await Future.delayed(
                              const Duration(milliseconds: 500));
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20 * widthScale,
                            vertical: 16 * heightScale,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: state.highDemands.length,
                          separatorBuilder: (_, __) => Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 12 * heightScale),
                            child: const Divider(
                              color: Color(0xFFFFD7C6),
                              thickness: 1,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final dish = state.highDemands[index];
                            return HighDemandListCard(
                              restaurantName: dish.restaurant.name,
                              dishName: dish.menuItem.name,
                              imageUrl: dish.menuItem.imageUrl ?? '',
                              distanceKm: dish.distanceKm,
                              rating: dish.restaurant.rating,
                              price: dish.menuItem.price,
                              orderCount: dish.menuItem.orderCount,
                              isDelivery:
                                  dish.restaurant.isDeliveryEnabled,
                              onTap: () {
                                Navigator.of(context).push(
                                  fadeSlideRoute(RestaurantDetailView(
                                    restaurantName: dish.restaurant.name,
                                    restaurantId: dish.restaurant.id,
                                  )),
                                );
                              },
                              onSeeInMap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LocationMapView(
                                      title: 'Restaurant Location',
                                      destinationName:
                                          dish.restaurant.name,
                                      destinationAddress:
                                          dish.restaurant.address,
                                      destinationLatitude:
                                          dish.restaurant.latitude,
                                      destinationLongitude:
                                          dish.restaurant.longitude,
                                    ),
                                  ),
                                );
                              },
                              onViewAll: () {
                                Navigator.of(context).push(
                                  fadeSlideRoute(RestaurantDetailView(
                                    restaurantName: dish.restaurant.name,
                                    restaurantId: dish.restaurant.id,
                                  )),
                                );
                              },
                            );
                          },
                        ),
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
          ),
        );
      },
    );
  }
}