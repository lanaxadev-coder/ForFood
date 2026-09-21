// ============================================================
// NOTIFICATION SETTING VIEW — PRODUCTION READY
// Real drawer + Persist toggles + Bottom Nav + Responsive
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/core/widgets/toggle_row.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/auth/user_role.dart';

import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class NotificationSettingView extends StatefulWidget {
  const NotificationSettingView({super.key});

  @override
  State<NotificationSettingView> createState() => _NotificationSettingViewState();
}

class _NotificationSettingViewState extends State<NotificationSettingView> {
  bool _generalNotif = true;
  bool _sound = true;
  bool _soundCall = true;
  bool _vibrate = false;
  int _currentIndex = 0;

  // ✅ Scaffold key + which drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DrawerType _activeDrawer = DrawerType.profile;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ✅ Load saved settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _generalNotif = prefs.getBool('notification_general') ?? true;
        _sound = prefs.getBool('notification_sound') ?? true;
        _soundCall = prefs.getBool('notification_sound_call') ?? true;
        _vibrate = prefs.getBool('notification_vibrate') ?? false;
      });
    }
  }

  // ✅ Save settings
  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
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
                  top: 76 * heightScale,
                  child: Text(
                    'Notification Settings ',
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
                  top: 160 * heightScale,
                  bottom: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 35 * widthScale,
                          vertical: 12 * heightScale,
                        ),
                        child: Column(
                          children: [
                            ToggleRow(
                              label: 'General Notification',
                              value: _generalNotif,
                              onChanged: (v) {
                                setState(() => _generalNotif = v);
                                _saveSetting('notification_general', v);
                              },
                            ),
                            ToggleRow(
                              label: 'Sound',
                              value: _sound,
                              onChanged: (v) {
                                setState(() => _sound = v);
                                _saveSetting('notification_sound', v);
                              },
                            ),
                            ToggleRow(
                              label: 'Sound Call',
                              value: _soundCall,
                              onChanged: (v) {
                                setState(() => _soundCall = v);
                                _saveSetting('notification_sound_call', v);
                              },
                            ),
                            ToggleRow(
                              label: 'Vibrate',
                              value: _vibrate,
                              onChanged: (v) {
                                setState(() => _vibrate = v);
                                _saveSetting('notification_vibrate', v);
                              },
                            ),
                          ],
                        ),
                      ),
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