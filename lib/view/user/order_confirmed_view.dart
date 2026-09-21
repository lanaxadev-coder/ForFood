// ============================================================
// ORDER CONFIRMED VIEW — success screen after placing an order
// ============================================================

import 'package:flutter/material.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/utilities/haptic_feedback.dart';
import 'package:forfood/utilities/page_transition.dart';

import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/my_order_view.dart';

class OrderConfirmedView extends StatelessWidget {
  final OrderModel order;
  final bool isDelivery;
  final String restaurantName;

  const OrderConfirmedView({
    super.key,
    required this.order,
    required this.isDelivery,
    required this.restaurantName,
  });

  String get _orderNumber {
    if (order.id.length >= 4) {
      return order.id.substring(order.id.length - 4).toUpperCase();
    }
    return order.id.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    // Fire haptic once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedbackUtil.medium();
    });

    return Scaffold(
      backgroundColor: AppColor.yellow,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30 * widthScale),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Big check icon
              Container(
                width: 110 * widthScale,
                height: 110 * widthScale,
                decoration: const BoxDecoration(
                  color: AppColor.orange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 60 * widthScale,
                ),
              ),

              SizedBox(height: 24 * heightScale),

              Text(
                'Order placed!',
                style: TextStyle(
                  color: AppColor.textDark,
                  fontSize: 28 * widthScale,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 8 * heightScale),

              Text(
                'Your order is on the way to the restaurant.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColor.textDark.withOpacity(0.75),
                  fontSize: 15 * widthScale,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 40 * heightScale),

              // Card with details
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20 * widthScale),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20 * widthScale),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order number',
                          style: TextStyle(
                            color: AppColor.gray,
                            fontSize: 13 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          '#$_orderNumber',
                          style: TextStyle(
                            color: AppColor.orange,
                            fontSize: 15 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12 * heightScale),
                    Container(height: 1, color: AppColor.divider),
                    SizedBox(height: 12 * heightScale),

                    // Restaurant
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'From',
                          style: TextStyle(
                            color: AppColor.gray,
                            fontSize: 13 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            restaurantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: AppColor.textDark,
                              fontSize: 15 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12 * heightScale),
                    Container(height: 1, color: AppColor.divider),
                    SizedBox(height: 12 * heightScale),

                    // Method
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Method',
                          style: TextStyle(
                            color: AppColor.gray,
                            fontSize: 13 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          isDelivery ? 'Delivery • ~35 min' : 'Pickup • ~20 min',
                          style: TextStyle(
                            color: AppColor.textDark,
                            fontSize: 15 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12 * heightScale),
                    Container(height: 1, color: AppColor.divider),
                    SizedBox(height: 12 * heightScale),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: AppColor.gray,
                            fontSize: 13 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          '\$${order.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColor.orange,
                            fontSize: 17 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Track order button
              GestureDetector(
                onTap: () {
                  HapticFeedbackUtil.medium();
                  Navigator.of(context).pushReplacement(
                    fadeSlideRoute(const MyOrdersView()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16 * heightScale),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColor.orange,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'Track order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12 * heightScale),

              // Back to home
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    fadeSlideRoute(const UserHomeView()),
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14 * heightScale),
                  alignment: Alignment.center,
                  child: Text(
                    'Back to home',
                    style: TextStyle(
                      color: AppColor.textDark,
                      fontSize: 15 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20 * heightScale),
            ],
          ),
        ),
      ),
    );
  }
}