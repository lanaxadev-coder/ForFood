import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/login_signUp_taps.dart';

class JoinUserRestaurantView extends StatelessWidget {
  const JoinUserRestaurantView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColor.orange,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 568 * heightScale,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 60 * widthScale),
                child: Text(
                  'Find the best restaurants near you, at prices that fit your budget.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColor.white,
                    fontFamily: 'League Spartan',
                    fontSize: 14 * widthScale,
                    fontWeight: FontWeight.normal,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 635 * heightScale,
              left: 72 * widthScale,
              child: InkWell(
              onTap: () {
  Navigator.of(context).push(
     fadeSlideRoute( const LoginSignupView(role: UserRole.user, isEmail: true,),
    ),
  );
},
                child: Container(
                  width: 258 * widthScale,
                  height: 45 * heightScale,
                  decoration: BoxDecoration(
                    color: AppColor.yellow,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      'Join As A User',
                      style: TextStyle(
                        color: AppColor.orange,
                        fontFamily: 'League Spartan',
                        fontSize: 20 * widthScale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 686 * heightScale,
              left: 72 * widthScale,
              child: InkWell(
                onTap: () {
  Navigator.of(context).push(
   fadeSlideRoute( const LoginSignupView(role: UserRole.restaurant, isEmail: true,),
    ),
  );
},
                child: Container(
                  width: 258 * widthScale,
                  height: 45 * heightScale,
                  decoration: BoxDecoration(
                    color: AppColor.yellow2,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      'Join as a Restaurant',
                      style: TextStyle(
                        color: AppColor.orange,
                        fontFamily: 'League Spartan',
                        fontSize: 20 * widthScale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 193 * heightScale,
              left: 106 * widthScale,
              child: Container(
                width: 214 * widthScale,
                height: 285 * heightScale,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Imageremovebgpreview11.png'),
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 478 * heightScale,
              left: 128 * widthScale,
              child: Container(
                width: 156 * widthScale,
                height: 51 * heightScale,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Text(
                        'For',
                        style: TextStyle(
                          color: AppColor.yellow,
                          fontFamily: 'Poppins',
                          fontSize: 34.85 * widthScale,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 62 * widthScale,
                      child: Text(
                        'Food',
                        style: TextStyle(
                          color: AppColor.white,
                          fontFamily: 'Poppins',
                          fontSize: 34.85 * widthScale,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}