// ============================================================
// TRIAL BANNER — PRODUCTION READY (RESPONSIVE)
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/service/subscription/trial_manager.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/restaurant/subscription_view.dart';

class TrialBanner extends StatelessWidget {
  final TrialStatusInfo statusInfo;

  const TrialBanner({super.key, required this.statusInfo});

  @override
  Widget build(BuildContext context) {
    switch (statusInfo.status) {
      case TrialStatus.active:
        return _buildNormalBanner(context);
      case TrialStatus.expiringSoon:
        return _buildUrgentBanner(context);
      case TrialStatus.expired:
        return _buildUpgradeBanner(context);
      case TrialStatus.premium:
        return const SizedBox.shrink();
      case TrialStatus.none:
        return _buildUpgradeBanner(context);
    }
  }

  Widget _buildNormalBanner(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return Container(
      height: 26 * widthScale,
      padding: EdgeInsets.only(left: 12 * widthScale, right: 8 * widthScale),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColor.orange,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      child: Text(
        '${statusInfo.message}  >',
        style: TextStyle(
          color: AppColor.white,
          fontSize: 12 * widthScale,
          fontFamily: 'League Spartan',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUrgentBanner(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return Container(
      height: 30 * widthScale,
      padding: EdgeInsets.symmetric(horizontal: 12 * widthScale),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      child: Text(
        statusInfo.message,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11 * widthScale,
          fontFamily: 'League Spartan',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildUpgradeBanner(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
           fadeSlideRoute( const SubscriptionView(),
          ),
        );
      },
      child: Container(
        height: 30 * widthScale,
        width: 160 * widthScale,
        padding: EdgeInsets.symmetric(horizontal: 12 * widthScale),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColor.orange,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
        ),
        child: Text(
          'Upgrade Now  >',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12 * widthScale,
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}