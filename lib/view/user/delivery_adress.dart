// ============================================================
// DELIVERY ADDRESS VIEW — PRODUCTION READY
// Real drawer + Bottom Nav + Responsive + Skeleton
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';

import 'package:forfood/models/address_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/user/add_address_view.dart';
import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class DeliveryAddressView extends StatefulWidget {
  const DeliveryAddressView({super.key});

  @override
  State<DeliveryAddressView> createState() => _DeliveryAddressViewState();
}

class _DeliveryAddressViewState extends State<DeliveryAddressView> {
  int _selectedIndex = 0;
  int _currentIndex = 0;

  // ✅ Scaffold key for reliable drawer opening
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ✅ Which drawer to show
  DrawerType _activeDrawer = DrawerType.profile;

  final FirestoreProvider _firestoreProvider = FirestoreProvider();
  StreamSubscription<List<AddressModel>>? _subscription;
  List<AddressModel> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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

  void _fetchAddresses() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      _subscription?.cancel();
      _subscription = _firestoreProvider
          .streamAddressesByUserId(authState.user.id)
          .listen(
        (addresses) {
          if (mounted) {
            setState(() {
              _addresses = addresses;
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      );
    }
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
                  left: 116 * widthScale,
                  top: 76 * heightScale,
                  child: Text(
                    'Delivery Address',
                    style: TextStyle(
                      color: AppColor.nearWhite,
                      fontSize: 28 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  top: 163 * heightScale,
                  bottom: 0,
                  child: Column(
                    children: [
                      SizedBox(height: 40 * heightScale),
                      Expanded(
                        child: _isLoading
                            ? ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 35 * widthScale),
                                itemCount: 3,
                                itemBuilder: (context, index) => Padding(
                                  padding: EdgeInsets.only(bottom: 16 * heightScale),
                                  child: Container(
                                    height: 70 * heightScale,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0E0E0),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              )
                            : _addresses.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.location_off,
                                          color: AppColor.orange,
                                          size: 60 * widthScale,
                                        ),
                                        SizedBox(height: 20 * heightScale),
                                        Text(
                                          'No addresses yet',
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
                                          'Add your first delivery address',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColor.gray,
                                            fontSize: 14 * widthScale,
                                            fontFamily: 'League Spartan',
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    color: AppColor.orange,
                                    onRefresh: () async {
                                      _fetchAddresses();
                                      await Future.delayed(const Duration(milliseconds: 500));
                                    },
                                    child: ListView.builder(
                                      padding: EdgeInsets.symmetric(horizontal: 35 * widthScale),
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: _addresses.length,
                                      itemBuilder: (context, index) {
                                        final address = _addresses[index];
                                        return Column(
                                          children: [
                                            Container(height: 1, color: AppColor.divider),
                                            GestureDetector(
                                              onTap: () => setState(() => _selectedIndex = index),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(vertical: 16 * heightScale),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_on,
                                                      color: AppColor.orange,
                                                      size: 29 * widthScale,
                                                    ),
                                                    SizedBox(width: 16 * widthScale),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            address.label,
                                                            style: TextStyle(
                                                              color: AppColor.textDark,
                                                              fontSize: 20 * widthScale,
                                                              fontFamily: 'League Spartan',
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                          Text(
                                                            address.fullAddress,
                                                            style: TextStyle(
                                                              color: AppColor.textDark,
                                                              fontSize: 14 * widthScale,
                                                              fontFamily: 'League Spartan',
                                                              fontWeight: FontWeight.w300,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Icon(
                                                      _selectedIndex == index
                                                          ? Icons.radio_button_checked
                                                          : Icons.radio_button_off,
                                                      color: AppColor.orange,
                                                      size: 20 * widthScale,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          fadeSlideRoute(const AddAddressView()),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20 * widthScale,
                            vertical: 8 * heightScale,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDECF),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Add New Address',
                            style: TextStyle(
                              color: AppColor.red,
                              fontSize: 17 * widthScale,
                              fontFamily: 'League Spartan',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20 * heightScale),
                    ],
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