// ============================================================
// MENU LIST VIEW — PRODUCTION READY
// Fixed: Restaurant ID + Bottom Nav + Taps + Refresh + Error + Empty
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/menu_list_item.dart';
import 'package:forfood/core/widgets/skeleton_loader.dart';

import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/menu/menu_bloc.dart';
import 'package:forfood/service/menu/menu_event.dart';
import 'package:forfood/service/menu/menu_state.dart';
import 'package:forfood/service/restaurant/restaurant_bloc.dart';
import 'package:forfood/service/restaurant/restaurant_event.dart';
import 'package:forfood/service/restaurant/restaurant_state.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/restaurant/add_item_in_menu.dart';
import 'package:forfood/view/restaurant/home_page.dart';
import 'package:forfood/view/restaurant/incoming_order.dart';
import 'package:forfood/view/restaurant/profile.dart';

class MenuListView extends StatefulWidget {
  const MenuListView({super.key});

  @override
  State<MenuListView> createState() => _MenuListViewState();
}

class _MenuListViewState extends State<MenuListView> {
  int _currentIndex = 3;
  String? _restaurantId;

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  // ✅ FIXED: This is the method name — use this everywhere
  void _fetchMenu() {
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

        return BlocBuilder<RestaurantBloc, RestaurantState>(
          builder: (context, restaurantState) {
            if (restaurantState is RestaurantStateLoaded) {
              restaurantName = restaurantState.restaurant.name;
              if (_restaurantId != restaurantState.restaurant.id) {
                _restaurantId = restaurantState.restaurant.id;
                context.read<MenuBloc>().add(
                      MenuEventFetchByRestaurant(restaurantId: _restaurantId!),
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
                      top: 75 * heightScale,
                      left: 141 * widthScale,
                      child: Text(
                        'Your Menu',
                        style: TextStyle(
                          color: AppColor.nearWhite,
                          fontSize: 28 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w700,
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
                      left: 0,
                      right: 0,
                      top: 160 * heightScale,
                      bottom: 0,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 17 * widthScale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 30 * heightScale),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Menu',
                                  style: TextStyle(
                                    color: AppColor.black,
                                    fontSize: 18 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                     fadeSlideRoute(const AddMenuItemView(),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Add',
                                        style: TextStyle(
                                          color: AppColor.orange,
                                          fontFamily: 'League Spartan',
                                          fontSize: 18 * widthScale,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 6 * widthScale),
                                      SvgPicture.asset(
                                        'assets/icons/AddDocumenticon.svg',
                                        width: 20 * widthScale,
                                        height: 20 * heightScale,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 10 * heightScale),

                            BlocBuilder<MenuBloc, MenuState>(
                              builder: (context, menuState) {
                                if (menuState is MenuStateLoading) {
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: 4,
                                    itemBuilder: (context, index) => Padding(
                                      padding: EdgeInsets.only(bottom: 16 * heightScale),
                                      child: const MenuListItemSkeleton(),
                                    ),
                                  );
                                }

                                if (menuState is MenuStateLoaded) {
                                  final menuItems = menuState.menuItems;

                                  if (menuItems.isEmpty) {
                                    return Padding(
                                      padding: EdgeInsets.all(40 * widthScale),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.restaurant_menu,
                                              color: AppColor.orange,
                                              size: 60 * widthScale,
                                            ),
                                            SizedBox(height: 20 * heightScale),
                                            Text(
                                              'No menu items yet',
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
                                              'Add your first item to start receiving orders',
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
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  fadeSlideRoute( const AddMenuItemView(),
                                                  ),
                                                );
                                              },
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
                                                  'Add Item',
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
                                      ),
                                    );
                                  }

                                  // ✅ RefreshIndicator wraps the loaded list
                                  return RefreshIndicator(
                                    color: AppColor.orange,
                                    onRefresh: () async {
                                      _fetchMenu();
                                      await Future.delayed(const Duration(milliseconds: 500));
                                    },
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: menuItems.length,
                                      itemBuilder: (context, index) {
                                        final item = menuItems[index];
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: 16 * heightScale),
                                          child: MenuListItem(
                                            imageUrl: item.imageUrl ?? 'https://picsum.photos/105/81',
                                            name: item.name,
                                            price: '\$${item.price.toStringAsFixed(2)}',
                                            onTap: () {
                                              Navigator.of(context).push(
                                              fadeSlideRoute(AddMenuItemView(
                                                    editItem: item,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }

                                if (menuState is MenuStateError) {
                                  return Padding(
                                    padding: EdgeInsets.all(40 * widthScale),
                                    child: Center(
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
                                              menuState.message,
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
                                            onTap: () {
                                              _fetchMenu();
                                            },
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
                  isRestaurant: true,  // ✅ ADD THIS

              ),
            );
          },
        );
      },
    );
  }
}