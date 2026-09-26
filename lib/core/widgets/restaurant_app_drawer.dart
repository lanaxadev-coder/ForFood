// ============================================================
// RESTAURANT APP DRAWER — LOCALIZED + PROPERLY SPACED
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:forfood/core/theme/app_color.dart';

class RestaurantAppDrawer extends StatelessWidget {
  final String name;
  final String email;
  final String? profileImageUrl;
  final void Function(BuildContext context) onMyProfile;
  final void Function(BuildContext context) onSubscription;
  final void Function(BuildContext context) onContactUs;
  final void Function(BuildContext context) onHelpFAQs;
  final void Function(BuildContext context) onSettings;
  final void Function(BuildContext context) onLogout;
  final void Function(BuildContext context) onReviews;    // 👈 NEW

  const RestaurantAppDrawer({
    super.key,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.onMyProfile,
    required this.onSubscription,
      required this.onReviews,                              // 👈 NEW

    required this.onContactUs,
    required this.onHelpFAQs,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70),
          bottomLeft: Radius.circular(70),
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const ShapeDecoration(
          color: AppColor.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              bottomLeft: Radius.circular(60),
            ),
          ),
        ),
        child: Stack(
          children: [
            // Profile image
            Positioned(
              left: 33,
              top: 65,
              child: GestureDetector(
                    onTap: () => onMyProfile(context),

                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const ShapeDecoration(
                    color: Color.fromARGB(255, 245, 223, 113),
                    shape: OvalBorder(),
                  ),
                  child: ClipOval(
                    child: (profileImageUrl != null &&
                            profileImageUrl!.isNotEmpty)
                        ? Image.network(
                            profileImageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: AppColor.nearWhite,
                              size: 30,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: AppColor.nearWhite,
                            size: 30,
                          ),
                  ),
                ),
              ),
            ),

            // Name
          // Name + Email (tappable)
Positioned(
  left: 100,
  top: 60,
  child: GestureDetector(
    onTap: () => onMyProfile(context),
    child: SizedBox(
      width: 209,
      height: 55,  // covers both name and email
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 31,
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColor.nearWhite,
                fontSize: 27,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 20,
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColor.nearWhite,
                fontSize: 14,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
),
            // ─── MENU ITEMS (evenly spaced at 75px intervals) ───

                      // My Profile — y=170
            _buildMenuItem(
              iconPosition: const Offset(33, 170),
              textPosition: const Offset(100, 181),
              icon: 'assets/icons/profile.svg',
              text: 'My Profile',
              onTap: () => onMyProfile(context),
            ),
            _buildDivider(33, 225),

            // Subscription — y=245
            _buildMenuItem(
              iconPosition: const Offset(33, 245),
              textPosition: const Offset(100, 255),
              icon: 'assets/icons/subscription.svg',
              text: 'Subscription',
              onTap: () => onSubscription(context),
            ),
            _buildDivider(33, 300),

            // 👈 NEW — Reviews at y=320
            _buildMenuItem(
              iconPosition: const Offset(33, 320),
              textPosition: const Offset(100, 330),
              icon: 'assets/icons/reviewIcon.svg',   // reuse your star SVG
              text: 'Reviews',
              onTap: () => onReviews(context),
            ),
            _buildDivider(33, 375),

            // Contact Us — y=395
            _buildMenuItem(
              iconPosition: const Offset(33, 395),
              textPosition: const Offset(100, 405),
              icon: 'assets/icons/contactUs.svg',
              text: 'Contact Us',
              onTap: () => onContactUs(context),
            ),
            _buildDivider(33, 450),

            // Help & FAQs — y=470
            _buildMenuItem(
              iconPosition: const Offset(33, 470),
              textPosition: const Offset(100, 480),
              icon: 'assets/icons/helpFQA.svg',
              text: 'Help & FAQs',
              onTap: () => onHelpFAQs(context),
            ),
            _buildDivider(33, 525),

            // Settings — y=545
            _buildMenuItem(
              iconPosition: const Offset(33, 545),
              textPosition: const Offset(100, 555),
              icon: 'assets/icons/settings.svg',
              text: 'Settings',
              onTap: () => onSettings(context),
            ),
            _buildDivider(33, 600),

            // Logout — y=660
            _buildMenuItem(
              iconPosition: const Offset(42, 660),
              textPosition: const Offset(100, 670),
              icon: 'assets/icons/Component 50.svg',
              text: 'Log Out',
              onTap: () => onLogout(context),
              isSmallIcon: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 240,
        decoration: const ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 0.5,
              strokeAlign: BorderSide.strokeAlignCenter,
              color: Color(0xFFFFD7C6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required Offset iconPosition,
    required Offset textPosition,
    required String icon,
    required String text,
    required VoidCallback onTap,
    bool isSmallIcon = false,
  }) {
    return Positioned(
      left: iconPosition.dx,
      top: iconPosition.dy,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: ShapeDecoration(
                color: const Color(0xFFF8F8F8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  icon,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: textPosition.dx -
                    iconPosition.dx -
                    (isSmallIcon ? 32 : 40.30),
              ),
              child: SizedBox(
                width: 200,
                height: 31,
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFF3E9B5),
                    fontSize: 23,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w500,
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