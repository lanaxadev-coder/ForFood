// ============================================================
// PASSWORD SETTING VIEW — PRODUCTION READY
// Real drawer + Bottom Nav + Responsive + Keyboard Dismiss
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';

import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_event.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class PasswordSettingView extends StatefulWidget {
  const PasswordSettingView({super.key});

  @override
  State<PasswordSettingView> createState() => _PasswordSettingViewState();
}

class _PasswordSettingViewState extends State<PasswordSettingView> {
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleChangePassword() {
    final newPassword = _newController.text;
    final confirmPassword = _confirmController.text;

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      setState(() => _isLoading = true);

      context.read<AuthBloc>().add(
            AuthEventForgotPassword(email: authState.user.email),
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email! Check your inbox.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );

      setState(() => _isLoading = false);
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
      Scaffold.of(context).openEndDrawer();
      break;
    case 4:
      Scaffold.of(context).openEndDrawer();
      break;
  }
}

  Widget _passwordField(
    String label,
    TextEditingController controller, {
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColor.textDark,
            fontSize: 18 * widthScale,
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF3E9B5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: controller,
            obscureText: !isVisible,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              hintText: '*************',
              hintStyle: const TextStyle(
                color: AppColor.gray,
                fontFamily: 'League Spartan',
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
              suffixIcon: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/ShowOff.svg',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
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

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
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
                    left: 100 * widthScale,
                    top: 76 * heightScale,
                    child: Text(
                      'Password Setting',
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
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 35 * widthScale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 50 * heightScale),

                          Container(
                            padding: EdgeInsets.all(15 * widthScale),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDECF),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: AppColor.orange, size: 24 * widthScale),
                                SizedBox(width: 10 * widthScale),
                                Expanded(
                                  child: Text(
                                    'For security, we\'ll send a password reset link to your email.',
                                    style: TextStyle(
                                      color: AppColor.textDark,
                                      fontSize: 14 * widthScale,
                                      fontFamily: 'League Spartan',
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 30 * heightScale),

                          _passwordField(
                            'New Password',
                            _newController,
                            isVisible: _isNewPasswordVisible,
                            onToggleVisibility: () => setState(
                                () => _isNewPasswordVisible = !_isNewPasswordVisible),
                          ),
                          _passwordField(
                            'Confirm New Password',
                            _confirmController,
                            isVisible: _isConfirmPasswordVisible,
                            onToggleVisibility: () => setState(() =>
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible),
                          ),
                          SizedBox(height: 80 * heightScale),
                          Center(
                            child: GestureDetector(
                              onTap: _isLoading ? null : _handleChangePassword,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 30 * widthScale,
                                  vertical: 10 * heightScale,
                                ),
                                decoration: BoxDecoration(
                                  color: _isLoading ? AppColor.gray : AppColor.orange,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 24 * widthScale,
                                        height: 24 * heightScale,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Send Reset Link',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17 * widthScale,
                                          fontFamily: 'League Spartan',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
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
          ),
        );
      },
    );
  }
}