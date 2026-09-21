import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
        color: AppColor.yellow,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 490 * heightScale,
              left: 130 * widthScale,
              child: SizedBox(
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
                          color: AppColor.orange,
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
            Positioned(
              top: 217 * heightScale,
              left: 87 * widthScale,
              child: Container(
                width: 227 * widthScale,
                height: 285 * heightScale,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Imageremovebgpreview21.png'),
                    fit: BoxFit.contain,
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