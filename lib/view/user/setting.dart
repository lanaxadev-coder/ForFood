// ============================================================
// SETTINGS VIEW — PRODUCTION READY (RESPONSIVE + ALL SETTINGS)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/core/widgets/settings_row.dart';
import 'package:forfood/core/widgets/show_delete_user_dialog.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';
import 'package:forfood/view/user/language_settings.dart';
import 'package:forfood/view/user/notification_setting.dart';
import 'package:forfood/view/user/password_setting.dart';
import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int _currentIndex = 0;

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
        // ✅ Cart tab → cart drawer
        _openCartDrawer();
        break;
      case 4:
        // ✅ Profile tab → profile drawer
        _openProfileDrawer();
        break;
    }
  }

  // ✅ Picks which drawer renders (preserves restaurant vs user logic)
  Widget _buildActiveDrawer(
    String userName,
    String userEmail,
    String? profileImageUrl,
    bool isRestaurant,
  ) {
    switch (_activeDrawer) {
      case DrawerType.profile:
        return isRestaurant
            ? buildRestaurantDrawer(
                name: userName,
                email: userEmail,
                profileImageUrl: profileImageUrl,
              )
            : buildUserDrawer(
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
        bool isRestaurant = false;

        if (authState is AuthStateLoggedIn) {
          userName = authState.user.fullName;
          userEmail = authState.user.email;
          profileImageUrl = authState.user.profileImageUrl;
          isRestaurant = authState.user.role == UserRole.restaurant;
        }

        return Scaffold(
          key: _scaffoldKey,
          // ✅ Dynamic drawer
          endDrawer: _buildActiveDrawer(
            userName,
            userEmail,
            profileImageUrl,
            isRestaurant,
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
                // White bottom section
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
                  left: 145 * widthScale,
                  top: 76 * heightScale,
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: AppColor.nearWhite,
                      fontSize: 30 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Content
                Positioned(
                  left: 0,
                  right: 0,
                  top: 200 * heightScale,
                  bottom: 0,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 35 * widthScale),
                    child: Column(
                      children: [
                        // Notification
                        SettingsRow(
                          icon: SvgPicture.asset(
                            'assets/icons/Notification Icon.svg',
                            height: 30 * heightScale,
                            width: 30 * widthScale,
                            color: AppColor.orange,
                            fit: BoxFit.contain,
                          ),
                          label: 'Notification Setting',
                          onTap: () {
                            Navigator.of(context).push(
                          fadeSlideRoute(
                                    const NotificationSettingView(),
                              ),
                            );
                          },
                        ),

                        // Password
                        SettingsRow(
                          icon: SvgPicture.asset(
                            'assets/icons/Key Icon.svg',
                            height: 30 * heightScale,
                            width: 30 * widthScale,
                            color: AppColor.orange,
                            fit: BoxFit.contain,
                          ),
                          label: 'Password Setting',
                          onTap: () {
                            Navigator.of(context).push(
                             fadeSlideRoute( const PasswordSettingView(),
                              ),
                            );
                          },
                        ),

                        // Privacy Policy
                        SettingsRow(
                          icon: Icon(Icons.privacy_tip_outlined, color: AppColor.orange, size: 30),
                          label: 'Privacy Policy',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColor.nearWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    color: AppColor.orange,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                  ),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        '1. Data We Collect',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '• Email address\n• Full name\n• Phone number (optional)\n• Profile photo (optional)\n• Restaurant address (for restaurants)',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          height: 1.5,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '2. How We Use Your Data',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '• To create and manage your account\n• To process your orders\n• To show nearby restaurants\n• To send order notifications',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          height: 1.5,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '3. Data Security',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Your data is stored securely in Firebase. We never sell your personal information to third parties.',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Close',
                                      style: TextStyle(
                                        color: AppColor.orange,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Terms of Service
                        SettingsRow(
                          icon: Icon(Icons.description_outlined, color: AppColor.orange, size: 30),
                          label: 'Terms of Service',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColor.nearWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text(
                                  'Terms of Service',
                                  style: TextStyle(
                                    color: AppColor.orange,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                  ),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        '1. Acceptance of Terms',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'By using ForFood, you agree to these terms and conditions.',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          height: 1.5,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '2. User Accounts',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '• You must be 18+ to create an account\n• You are responsible for your account security\n• You must provide accurate information',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          height: 1.5,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '3. Restaurant Responsibilities',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '• Provide accurate menu and pricing\n• Maintain food safety standards\n• Honor orders placed through ForFood',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          height: 1.5,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '4. Orders & Payments',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '• Payment is Cash on Delivery (COD)\n• Prices shown include all applicable taxes\n• Restaurants may cancel orders if items unavailable',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontFamily: 'League Spartan',
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Close',
                                      style: TextStyle(
                                        color: AppColor.orange,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // App Version
                        SettingsRow(
                          icon: Icon(Icons.info_outline, color: AppColor.orange, size: 30),
                          label: 'App Version',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColor.nearWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text(
                                  'ForFood',
                                  style: TextStyle(
                                    color: AppColor.orange,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24,
                                  ),
                                ),
                                content: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.restaurant, color: AppColor.orange, size: 50),
                                    SizedBox(height: 12),
                                    Text(
                                      'Version 1.0.0',
                                      style: TextStyle(
                                        color: AppColor.textDark,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Built with ❤️ for food lovers.\n© 2026 ForFood. All rights reserved.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColor.gray,
                                        fontFamily: 'League Spartan',
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Close',
                                      style: TextStyle(
                                        color: AppColor.orange,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Language row
                        SettingsRow(
                          icon: Icon(Icons.language, color: AppColor.orange, size: 30),
                          label: 'Language',
                          onTap: () {
                            Navigator.of(context).push(
                            fadeSlideRoute( const LanguageSettingView(),
                              ),
                            );
                          },
                        ),

                        // Delete Account (red)
                        SettingsRow(
                          icon: SvgPicture.asset(
                            'assets/icons/User Icon.svg',
                            height: 30 * heightScale,
                            width: 30 * widthScale,
                            color: Colors.red,
                            fit: BoxFit.contain,
                          ),
                          label: 'Delete Account',
                          onTap: () {
                            showDeleteUserDialog(context);
                          },
                        ),
                        SizedBox(height: 20 * heightScale),
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
          ),
        );
      },
    );
  }
}