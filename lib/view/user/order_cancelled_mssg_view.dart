// ============================================================
// ORDER CANCELLED VIEW — success screen after cancelling
// ============================================================

import 'package:flutter/material.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class OrderCancelledView extends StatefulWidget {
  const OrderCancelledView({super.key});

  @override
  State<OrderCancelledView> createState() => _OrderCancelledViewState();
}

class _OrderCancelledViewState extends State<OrderCancelledView> {
  int _currentIndex = 0;

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

      Scaffold.of(context).openEndDrawer();
      break;
    case 4:
          setState(() => _currentIndex = index);   // ✅ highlight

      Scaffold.of(context).openEndDrawer();
      break;
  }
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    return Scaffold(
      backgroundColor: AppColor.yellow,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ───────────── Back arrow ─────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 35 * widthScale,
                vertical: 12 * heightScale,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8 * widthScale),
                    child: Padding(
                      padding: EdgeInsets.all(4 * widthScale),
                      child: Image.asset(
                        'assets/icons/BackiconArrow.png',
                        width: 20 * widthScale,
                        height: 20 * heightScale,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ───────────── Centered content ─────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30 * widthScale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Circle-with-dot icon
                    Container(
                      width: 150 * widthScale,
                      height: 150 * widthScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColor.orange,
                          width: 6 * widthScale,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 14 * widthScale,
                          height: 14 * widthScale,
                          margin: EdgeInsets.only(left: 15 * widthScale),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColor.orange,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 30 * heightScale),

                    Text(
                      'Order Cancelled!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColor.textDark,
                        fontSize: 22 * widthScale,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10 * heightScale),

                    Text(
                      'Your order has been successfully cancelled',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColor.textDark,
                        fontSize: 14 * widthScale,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Flexible gap — pushes support text to the bottom
                    // of the centered block, but never overflows
                    SizedBox(height: 60 * heightScale),

                    Text(
                      'If you have any question reach directly to our customer support',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColor.textDark,
                        fontSize: 14 * widthScale,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
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
    );
  }
}