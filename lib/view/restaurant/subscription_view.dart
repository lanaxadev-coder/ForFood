// ============================================================
// SUBSCRIPTION VIEW — FIXED BOTTOM NAV + TERMS LINKS
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/chat_inbox_view.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';  // ✅ ADDED

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/pricing_card.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/revenuecat/revenuecat_service.dart';
import 'package:forfood/view/restaurant/home_page.dart';
import 'package:forfood/view/restaurant/incoming_order.dart';
import 'package:forfood/view/restaurant/menu.dart';
import 'package:forfood/view/restaurant/profile.dart';

class SubscriptionView extends StatefulWidget {
  final bool isFromSignup;

  const SubscriptionView({
    super.key,
    this.isFromSignup = false,
  });

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  int _currentIndex = 0;
  bool _isLoading = false;
  List<Package> _packages = [];

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    try {
      final packages = await RevenueCatService.getPackages();
      if (mounted) {
        setState(() {
          _packages = packages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePurchase(Package package) async {
    setState(() => _isLoading = true);
    try {
      final customerInfo = await RevenueCatService.purchasePackage(package);

      if (customerInfo.entitlements.active.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription activated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          if (widget.isFromSignup) {
            Navigator.of(context).pushAndRemoveUntil(
              fadeSlideRoute(const RestaurantHomeView()),
              (route) => false,
            );
          } else {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleStartTrial() {
    Package? trialPackage;

    for (final package in _packages) {
      if (package.storeProduct.subscriptionPeriod == 'P1M' &&
          package.storeProduct.introductoryPrice != null) {
        trialPackage = package;
        break;
      }
    }

    if (trialPackage != null) {
      _handlePurchase(trialPackage);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trial not available. Please select a plan.')),
      );
    }
  }

  // ✅ ADDED: Launch URLs
  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  // ✅ FIXED: Bottom nav navigation
 void _handleBottomNavTap(int index) {
  if (index == _currentIndex) return;

  switch (index) {
    case 0:
      Navigator.of(context).pushAndRemoveUntil(
        fadeSlideRoute(const RestaurantHomeView()),
        (route) => false,
      );
      break;
    case 1:
      Navigator.of(context).pushAndRemoveUntil(
        fadeSlideRoute(const OrdersView()),
        (route) => false,
      );
      break;
    case 2:
      Navigator.of(context).push(fadeSlideRoute(const ChatInboxView()));
      break;
    case 3:
      Navigator.of(context).push(fadeSlideRoute(const MenuListView()));
      break;
    case 4:
      Navigator.of(context).push(
        fadeSlideRoute(const ProfileViewRestaurant()),
      );
      break;
  }
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

        if (authState is AuthStateLoggedIn) {
          userName = authState.user.fullName;
          userEmail = authState.user.email;
          profileImageUrl = authState.user.profileImageUrl;
        }

        return Scaffold(
          endDrawer: widget.isFromSignup
              ? null
              : buildRestaurantDrawer(
                  name: userName,
                  email: userEmail,
                  profileImageUrl: profileImageUrl,
                ),
          body: Container(
            width: screenWidth,
            height: screenHeight,
            color: AppColor.yellow,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 80 * heightScale),
                  Row(
                    children: [
                      SizedBox(width: 35 * widthScale),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/icons/BackiconArrow.png',
                          width: 20 * widthScale,
                          height: 20 * heightScale,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 25 * heightScale),
                  Container(
                    width: 150 * widthScale,
                    height: 150 * heightScale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColor.orange, width: 6),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 14 * widthScale,
                        height: 14 * heightScale,
                        margin: EdgeInsets.only(left: 15 * widthScale),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.orange,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 25 * heightScale),
                  Text(
                    'Get your restaurant on ForFood',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColor.brown,
                      fontFamily: 'Inter',
                      fontSize: 22 * widthScale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 25 * heightScale),
                  Padding(
                    padding: EdgeInsets.all(8 * widthScale),
                    child: Text(
                      'Try it free for 6 months. Reach customers searching for food that fits their budget, nearby',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColor.brown,
                        fontFamily: 'League Spartan',
                        fontSize: 14 * widthScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 40 * heightScale),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: AppColor.orange))
                  else ...[
                    PricingCard(
                      planName: 'Yearly',
                      subtitle: '6 months free, then \$40/yr',
                      price: '\$40',
                      onTap: () {
                        if (_packages.isNotEmpty) {
                          final yearlyPackage = _packages.firstWhere(
                            (p) => p.storeProduct.identifier == 'forfood_yearly',
                            orElse: () => _packages.first,
                          );
                          _handlePurchase(yearlyPackage);
                        }
                      },
                      perMonthYear: '/yr',
                    ),
                    SizedBox(height: 25 * heightScale),
                    PricingCard(
                      planName: 'Monthly',
                      subtitle: '6 months free, then \$5/mo',
                      price: '\$5',
                      onTap: () {
                        if (_packages.isNotEmpty) {
                          final monthlyPackage = _packages.firstWhere(
                            (p) => p.storeProduct.identifier == 'forfood_monthly',
                            orElse: () => _packages.first,
                          );
                          _handlePurchase(monthlyPackage);
                        }
                      },
                      perMonthYear: '/mo',
                    ),
                  ],

                  SizedBox(height: 30 * heightScale),
                  GestureDetector(
                    onTap: _isLoading ? null : _handleStartTrial,
                    child: Container(
                      width: 351 * widthScale,
                      height: 60 * heightScale,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        color: _isLoading ? AppColor.gray : AppColor.orange,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Start Free Trial',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'League Spartan',
                          fontSize: 20 * widthScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30 * heightScale),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20 * widthScale),
                    child: Text(
                      'No charge for 6 months. Cancel anytime before your trial ends. Subscription auto-renews unless cancelled',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColor.brown,
                        fontFamily: 'League Spartan',
                        fontSize: 12 * widthScale,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  SizedBox(height: 55 * heightScale),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _launchUrl('https://www.forfood.com/terms-of-service'),
                        child: Text(
                          'Terms of Service',
                          style: TextStyle(
                            color: AppColor.orange,
                            fontFamily: 'League Spartan',
                            fontSize: 10 * widthScale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 20 * widthScale),
                      GestureDetector(
                        onTap: () => _launchUrl('https://www.forfood.com/privacy-policy'),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: AppColor.orange,
                            fontFamily: 'League Spartan',
                            fontSize: 10 * widthScale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30 * heightScale),
                ],
              ),
            ),
          ),
          bottomNavigationBar: widget.isFromSignup
              ? null
              : BottomNavBar(
                  currentIndex: _currentIndex,
                  onTap: _handleBottomNavTap,
                ),
        );
      },
    );
  }
}