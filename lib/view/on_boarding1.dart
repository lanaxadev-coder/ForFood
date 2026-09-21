import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/join_user_restaurant.dart';
import 'package:forfood/view/on_boarding2.dart';

class OnBoarding1 extends StatelessWidget {
  const OnBoarding1({super.key});

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
            // Background image
            Positioned(
              top: 0,
              left: 0,
              width: screenWidth,
              height: screenHeight,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Rectangle145.png'),
                    fit: BoxFit.cover,
                  ),
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

            // Filter icon
            Positioned(
              top: 538 * heightScale,
              left: 172 * widthScale,
              child: SvgPicture.asset(
                'assets/icons/FiltersIcon.svg',
                width: 37 * widthScale,
                height: 37 * heightScale,
                fit: BoxFit.contain,
              ),
            ),

            // Title
            Positioned(
              top: 594 * heightScale,
              left: 0,
              right: 0,
              child: Text(
                'Find food you can afford',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColor.orange,
                  fontFamily: 'Inter',
                  fontSize: 24 * widthScale,
                  fontWeight: FontWeight.normal,
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
                  "Search by what you're craving, your budget, and what's nearby — no more endless scrolling",
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
                      color: index == 0 ? AppColor.orange : AppColor.yellow2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }),
              ),
            ),

            // Next button
            Positioned(
              top: 751 * heightScale,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.of(context).push(
                      fadeSlideRoute(const OnBoarding2View(),
                      ),
                    );
                  },
                  child: Container(
                    width: 133 * widthScale,
                    height: 45 * heightScale,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColor.orange,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(
                        color: AppColor.white,
                        fontFamily: 'League Spartan',
                        fontSize: 17 * widthScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Skip button
            Positioned(
              top: 53 * heightScale,
              right: 27 * widthScale,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                  fadeSlideRoute( const JoinUserRestaurantView(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColor.orange,
                        fontFamily: 'League Spartan',
                        fontSize: 15 * widthScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4 * widthScale),
                    SvgPicture.asset(
                      'assets/icons/NexticonArrow.svg',
                      width: 8 * widthScale,
                      height: 13 * heightScale,
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