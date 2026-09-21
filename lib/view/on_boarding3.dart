import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/service/location/location_service.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/join_user_restaurant.dart';
import 'package:forfood/view/on_boarding2.dart';

class OnBoarding3View extends StatelessWidget {
  const OnBoarding3View({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    return Scaffold(
      backgroundColor: AppColor.yellow,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Background
            Positioned(
              top: 0,
              left: 0,
              width: screenWidth,
              height: screenHeight,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/cappuccini.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Back button
            Positioned(
              top: 48 * heightScale,
              left: 12 * widthScale,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    fadeSlideRoute( const OnBoarding2View(),
                    ),
                  );
                },
                child: SvgPicture.asset(
                  'assets/icons/ArrowLefticon.svg',
                  width: 13 * widthScale,
                  height: 13 * heightScale,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // White bottom sheet
            Positioned(
              top: 514 * heightScale,
              left: 0,
              child: Container(
                width: screenWidth,
                height: screenHeight - (514 * heightScale),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            // Location icon
            Positioned(
              top: 528 * heightScale,
              left: 170 * widthScale,
              child: SvgPicture.asset(
                'assets/icons/LocationMapicon.svg',
                width: 45 * widthScale,
                height: 45 * heightScale,
                fit: BoxFit.contain,
              ),
            ),

            // Title
            Positioned(
              top: 594 * heightScale,
              left: 0,
              right: 0,
              child: Text(
                "Find what's near you",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColor.orange,
                  fontFamily: 'Inter',
                  fontSize: 24 * widthScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Description
            Positioned(
              top: 642 * heightScale,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 60 * widthScale),
                child: Text(
                  "Only while you're using ForFood — you can change this anytime",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColor.brown,
                    fontFamily: 'League Spartan',
                    fontSize: 14 * widthScale,
                    fontWeight: FontWeight.normal,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            // Page indicator
            Positioned(
              top: 715 * heightScale,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    width: 20 * widthScale,
                    height: 4 * heightScale,
                    margin: EdgeInsets.symmetric(horizontal: 2 * widthScale),
                    decoration: BoxDecoration(
                      color: index == 2 ? AppColor.orange : AppColor.yellow2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }),
              ),
            ),

            // Get Started button
            Positioned(
              top: 741 * heightScale,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final locationService = LocationService();
                    await locationService.requestPermission();

                    if (!context.mounted) return;

                    Navigator.of(context).pushReplacement(
                      fadeSlideRoute(const JoinUserRestaurantView(),
                      ),
                    );
                  },
                  child: Container(
                    width: 119 * widthScale,
                    height: 45 * heightScale,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColor.orange,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Get Started',
                      style: TextStyle(
                        color: AppColor.white,
                        fontFamily: 'League Spartan',
                        fontSize: 17 * widthScale,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}