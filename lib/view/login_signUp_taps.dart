import 'package:flutter/material.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/join_user_restaurant.dart';
import 'package:forfood/view/restaurant/login_email.dart';
import 'package:forfood/view/restaurant/signup_email_verification.dart';
import 'package:forfood/view/user/login_email.dart';
import 'package:forfood/view/user/signup_email_verification.dart';

class LoginSignupView extends StatefulWidget {
  final UserRole role;
  final bool isEmail;

  const LoginSignupView({
    super.key,
    required this.role,
    required this.isEmail,
  });

  @override
  State<LoginSignupView> createState() => _LoginSignupViewState();
}

class _LoginSignupViewState extends State<LoginSignupView> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 393;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColor.orange,
        ),
        child: Stack(
          children: <Widget>[
            // Description
            Positioned(
              top: 568 * scale,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 60 * scale),
                child: Text(
                  'Find the best restaurants near you, at prices that fit your budget.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColor.white,
                    fontFamily: 'League Spartan',
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.normal,
                    height: 1.3,
                  ),
                ),
              ),
            ),

            // Log In button
            Positioned(
              top: 639 * scale,
              left: 93 * scale,
              child: InkWell(
                onTap: () {
                  if (widget.role == UserRole.user) {
                    Navigator.of(context).push(
                      fadeSlideRoute(
                            LoginWithEmailUserView(role: UserRole.user),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      fadeSlideRoute(
                            LoginWithEmailRestaurantView(role: UserRole.restaurant),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 207 * scale,
                  height: 45 * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: AppColor.yellow,
                  ),
                  child: Center(
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: AppColor.orange,
                        fontFamily: 'League Spartan',
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Sign Up button
            Positioned(
              top: 691 * scale,
              left: 93 * scale,
              child: InkWell(
                onTap: () {
                  if (widget.role == UserRole.user) {
                    Navigator.of(context).push(
                      fadeSlideRoute(SignupWithEmailUser(),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      fadeSlideRoute(SignupWithEmailRestaurant(),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 207 * scale,
                  height: 45 * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: AppColor.yellow2,
                  ),
                  child: Center(
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColor.orange,
                        fontFamily: 'League Spartan',
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Logo
            Positioned(
              top: 193 * scale,
              left: 106 * scale,
              child: Image.asset(
                'assets/images/Imageremovebgpreview11.png',
                width: 214 * scale,
                height: 285 * scale,
                fit: BoxFit.contain,
              ),
            ),

            // ForFood text
            Positioned(
              top: 478 * scale,
              left: 129 * scale,
              child: Row(
                children: [
                  Text(
                    'For',
                    style: TextStyle(
                      color: AppColor.yellow,
                      fontFamily: 'Poppins',
                      fontSize: 34.85 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Food',
                    style: TextStyle(
                      color: AppColor.white,
                      fontFamily: 'Poppins',
                      fontSize: 34.85 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Back button
            Positioned(
              left: 35 * scale,
              top: 84 * scale,
              child: InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                   fadeSlideRoute( const JoinUserRestaurantView(),
                    ),
                  );
                },
                child: Image.asset(
                  'assets/icons/BackiconArrow.png',
                  color: AppColor.yellow,
                  width: 20 * scale,
                  height: 20 * scale,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}