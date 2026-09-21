import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/join_user_restaurant.dart';
import 'package:forfood/view/on_boarding1.dart';
import 'package:forfood/view/on_boarding3.dart';

class OnBoarding2View extends StatelessWidget {
  const OnBoarding2View({super.key});

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
                    image: AssetImage('assets/images/Rectangle146.png'),
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

            // Back button
            Positioned(
              top: 48 * heightScale,
              left: 12 * widthScale,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    fadeSlideRoute( const OnBoarding1(),
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

            // Offer icon
            Positioned(
              top: 532 * heightScale,
              left: 168 * widthScale,
              child: Image.asset(
                'assets/icons/OfferIcon.png',
                width: 52 * widthScale,
                height: 50 * heightScale,
                fit: BoxFit.contain,
              ),
            ),

            // Title
            Positioned(
              top: 595 * heightScale,
              left: 0,
              right: 0,
              child: Text(
                'Cheapest, closest, best-rated',
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
                  'We sort every search so the best deal near you is always on top',
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
                      color: index == 1 ? AppColor.orange : AppColor.yellow2,
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
                  onTap: () {
                    Navigator.of(context).push(
                     fadeSlideRoute(const OnBoarding3View(),
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