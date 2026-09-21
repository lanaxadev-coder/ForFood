// lib/view/user/dark_mode_setting.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/toggle_row.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/auth/user_role.dart';

class DarkModeSettingView extends StatefulWidget {
  const DarkModeSettingView({super.key});

  @override
  State<DarkModeSettingView> createState() => _DarkModeSettingViewState();
}

class _DarkModeSettingViewState extends State<DarkModeSettingView> {
  int _currentIndex = 0;
  bool _darkMode = false;

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
          endDrawer: isRestaurant
              ? buildRestaurantDrawer(
                  name: userName,
                  email: userEmail,
                  profileImageUrl: profileImageUrl,
                )
              : buildUserDrawer(
                  name: userName,
                  email: userEmail,
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
                    'Dark Mode',
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 35 * widthScale),
                    child: ToggleRow(
                      label: 'Enable Dark Mode',
                      value: _darkMode,
                      onChanged: (v) {
                        setState(() => _darkMode = v);
                        // TODO: Save to SharedPreferences + update ThemeMode
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
          ),
        );
      },
    );
  }
}