// ============================================================
// LANGUAGE SETTING VIEW — PRODUCTION READY
// Wired to LanguageProvider + Bottom Nav + Drawer + Responsive
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forfood/view/user/my_order_view.dart';
import 'package:provider/provider.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/service/language/language_provider.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class LanguageSettingView extends StatefulWidget {
  const LanguageSettingView({super.key});

  @override
  State<LanguageSettingView> createState() => _LanguageSettingViewState();
}

class _LanguageSettingViewState extends State<LanguageSettingView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 4;

  // ✅ Which drawer to show
  DrawerType _activeDrawer = DrawerType.profile;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇩🇿'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
  ];

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

  Future<void> _saveLanguage(String languageCode) async {
    final languageProvider = context.read<LanguageProvider>();
    await languageProvider.changeLocale(languageCode);

    if (mounted) {
      final language = _languages.firstWhere(
        (l) => l['code'] == languageCode,
        orElse: () => {'name': languageCode},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language changed to ${language['name']}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
        Navigator.of(context).push(tabRoute(const MyOrdersView()));
        break;
      case 4:
            setState(() => _currentIndex = index);   // ✅ highlight

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

        return Consumer<LanguageProvider>(
          builder: (context, languageProvider, _) {
            final currentCode = languageProvider.locale.languageCode;

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
                      left: 130 * widthScale,
                      top: 76 * heightScale,
                      child: Text(
                        'Language',
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
                      top: 200 * heightScale,
                      bottom: 0,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: 35 * widthScale),
                        itemCount: _languages.length,
                        itemBuilder: (context, index) {
                          final language = _languages[index];
                          final isSelected =
                              language['code'] == currentCode;

                          return Column(
                            children: [
                              Container(
                                  height: 1, color: AppColor.divider),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Text(
                                  language['flag']!,
                                  style: TextStyle(
                                      fontSize: 24 * widthScale),
                                ),
                                title: Text(
                                  language['name']!,
                                  style: TextStyle(
                                    color: AppColor.textDark,
                                    fontSize: 20 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: AppColor.orange,
                                  size: 24 * widthScale,
                                ),
                                onTap: () =>
                                    _saveLanguage(language['code']!),
                              ),
                            ],
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
      },
    );
  }
}