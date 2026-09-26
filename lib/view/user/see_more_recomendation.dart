// ============================================================
// RECOMMENDATION LIST VIEW — PRODUCTION READY (COMBINED STATE)
// Real data + Skeleton + Responsive + Bottom Nav + Drawer
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/core/widgets/recommendation_list_card.dart';
import 'package:forfood/core/widgets/skeleton_loader.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_bloc.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_event.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_state.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';
import 'package:forfood/view/user/my_order_view.dart';

import 'package:forfood/view/user/retaurant_detail_screen.dart';
import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class RecommendationListView extends StatefulWidget {
  const RecommendationListView({super.key});

  @override
  State<RecommendationListView> createState() => _RecommendationListViewState();
}

class _RecommendationListViewState extends State<RecommendationListView> {
  int _currentIndex = 0;

  // ✅ Scaffold key + which drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DrawerType _activeDrawer = DrawerType.profile;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  void _fetchRecommendations() {
    context.read<RestaurantListBloc>().add(
          const RestaurantListEventFetchRecommendations(),
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
        // ✅ Cart tab → cart drawer
        Navigator.of(context).push(tabRoute(const MyOrdersView()));
        break;
      case 4:
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
            decoration: ShapeDecoration(
              color: const Color(0xFFF5CB58),
              shape: RoundedRectangleBorder(
              ),
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
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF5F5F5),
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
                    'Recommendation ',
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
                  child: BlocBuilder<RestaurantListBloc, RestaurantListState>(
                    builder: (context, state) {
                      // ✅ Loading
                      if (state.isLoadingRecommendations) {
                        return RefreshIndicator(
                          color: AppColor.orange,
                          onRefresh: () async {
                            _fetchRecommendations();
                            await Future.delayed(const Duration(milliseconds: 500));
                          },
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: 40 * widthScale,
                              vertical: 20 * heightScale,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: 4,
                            separatorBuilder: (context, index) => Container(
                              height: 1,
                              color: AppColor.divider,
                            ),
                            itemBuilder: (context, index) =>
                                const RestaurantCardSkeleton(),
                          ),
                        );
                      }

                      // ✅ Error
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
                                padding: EdgeInsets.symmetric(horizontal: 40 * widthScale),
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
                                onTap: _fetchRecommendations,
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

                      // ✅ Empty
                      if (state.recommendations.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant,
                                color: AppColor.orange,
                                size: 60 * widthScale,
                              ),
                              SizedBox(height: 20 * heightScale),
                              Text(
                                'No recommendations yet',
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
                                'Check back soon for new restaurants',
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
                                onTap: _fetchRecommendations,
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

                      // ✅ Data
                      return RefreshIndicator(
                        color: AppColor.orange,
                        onRefresh: () async {
                          _fetchRecommendations();
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: 40 * widthScale,
                            vertical: 20 * heightScale,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: state.recommendations.length,
                          separatorBuilder: (context, index) => Container(
                            height: 1,
                            color: AppColor.divider,
                          ),
                          itemBuilder: (context, index) {
                            final item = state.recommendations[index];
                            return RecommendationListCard(
                              imageUrl: item.restaurant.profileImageUrl ??
                                  'https://placehold.co/129/126',
                              name: item.restaurant.name,
                              distance:
                                  '${item.distanceKm.toStringAsFixed(1)} km',
                              rating:
                                  item.restaurant.rating.toStringAsFixed(1),
                              onTap: () {
                                Navigator.of(context).push(
                                  fadeSlideRoute(RestaurantDetailView(
                                    restaurantName: item.restaurant.name,
                                    restaurantId: item.restaurant.id,
                                  )),
                                );
                              },
                              onSeeMore: () {
                                Navigator.of(context).push(
                                  fadeSlideRoute(RestaurantDetailView(
                                    restaurantName: item.restaurant.name,
                                    restaurantId: item.restaurant.id,
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