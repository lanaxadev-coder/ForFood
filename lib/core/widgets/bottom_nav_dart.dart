// ============================================================
// BOTTOM NAV BAR — 5 items with chat unread badge
// Stateful: guarantees the tapped tab highlights immediately.
// Original clean visual: opacity only.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/auth/user_role.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isRestaurant;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isRestaurant = false,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _activeIndex;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _activeIndex = widget.currentIndex;
    }
  }

  void _handleTap(int index) {
    if (_activeIndex != index) {
      setState(() => _activeIndex = index);
    }
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    // ✅ Auto-detect restaurant role
    final authState = context.watch<AuthBloc>().state;
    final autoIsRestaurant = authState is AuthStateLoggedIn &&
        authState.user.role == UserRole.restaurant;
    final effectiveIsRestaurant = widget.isRestaurant || autoIsRestaurant;

    final icons = effectiveIsRestaurant
        ? [
            'assets/icons/homeWhite.svg',
            'assets/icons/orderWhite.svg',
            'assets/icons/chat.svg',
            'assets/icons/menuWhite.svg',
            'assets/icons/profileWhite.svg',
          ]
        : [
            'assets/icons/homeWhite.svg',
            'assets/icons/searchWhitee.svg',
            'assets/icons/chat.svg',
            'assets/icons/cartWhitee.svg',
            'assets/icons/profileWhite.svg',
          ];

    return Container(
      width: double.infinity,
      height: 61 * widthScale,
      clipBehavior: Clip.antiAlias,
      decoration: const ShapeDecoration(
        color: Color(0xFFE95322),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: icons[0],
            isActive: _activeIndex == 0,
            onTap: () {
              HapticFeedback.selectionClick();
              _handleTap(0);
            },
            width: 30 * widthScale,
            height: 30 * widthScale,
            semanticLabel: 'Home',
          ),
          _NavItem(
            icon: icons[1],
            isActive: _activeIndex == 1,
            onTap: () {
              HapticFeedback.selectionClick();
              _handleTap(1);
            },
            width: 30 * widthScale,
            height: 30 * widthScale,
            semanticLabel: effectiveIsRestaurant ? 'Orders' : 'Search',
          ),
          _ChatNavItem(
            icon: icons[2],
            isActive: _activeIndex == 2,
            onTap: () {
              HapticFeedback.selectionClick();
              _handleTap(2);
            },
            width: 30 * widthScale,
            height: 30 * widthScale,
            isRestaurant: effectiveIsRestaurant,
          ),
          _NavItem(
            icon: icons[3],
            isActive: _activeIndex == 3,
            onTap: () {
              HapticFeedback.selectionClick();
              _handleTap(3);
            },
            width: 30 * widthScale,
            height: 30 * widthScale,
            semanticLabel: effectiveIsRestaurant ? 'Menu' : 'Cart',
          ),
          _NavItem(
            icon: icons[4],
            isActive: _activeIndex == 4,
            onTap: () {
              HapticFeedback.selectionClick();
              _handleTap(4);
            },
            width: 32 * widthScale,
            height: 32 * widthScale,
            semanticLabel: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STANDARD ITEM — original clean opacity highlight
// ============================================================
class _NavItem extends StatelessWidget {
  final String icon;
  final bool isActive;
  final VoidCallback onTap;
  final double width;
  final double height;
  final String semanticLabel;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.width,
    required this.height,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Opacity(
            // ✅ Original: active = 1.0, inactive = 0.55 (slightly stronger
            //    than 0.7 so the difference is actually visible)
            opacity: isActive ? 1.0 : 0.55,
            child: SvgPicture.asset(
              icon,
              width: width,
              height: height,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CHAT ITEM — same clean opacity + red badge
// ============================================================
class _ChatNavItem extends StatelessWidget {
  final String icon;
  final bool isActive;
  final VoidCallback onTap;
  final double width;
  final double height;
  final bool isRestaurant;

  const _ChatNavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.width,
    required this.height,
    required this.isRestaurant,
  });

  @override
  Widget build(BuildContext context) {
    final widthScale = MediaQuery.of(context).size.width / 393;

    return Semantics(
      label: 'Messages',
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: isActive ? 1.0 : 0.55,
                child: SvgPicture.asset(
                  icon,
                  width: width,
                  height: height,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: _ChatBadge(widthScale: widthScale),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BADGE — matches the notification bell badge style
// ============================================================
class _ChatBadge extends StatelessWidget {
  final double widthScale;

  const _ChatBadge({required this.widthScale});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthStateLoggedIn) return const SizedBox.shrink();

    final uid = authState.user.id;
    final isRestaurantUser = authState.user.role == UserRole.restaurant;

    if (isRestaurantUser) {
      return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('restaurants')
            .where('ownerId', isEqualTo: uid)
            .limit(1)
            .get(),
        builder: (context, restSnap) {
          if (!restSnap.hasData || restSnap.data!.docs.isEmpty) {
            return const SizedBox.shrink();
          }
          return _buildStream(
            restSnap.data!.docs.first.id,
            'restaurant',
          );
        },
      );
    }

    return _buildStream(uid, 'user');
  }

  Widget _buildStream(String idToMatch, String myRole) {
    final field = myRole == 'restaurant' ? 'restaurantId' : 'userId';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where(field, isEqualTo: idToMatch)
          .where('lastMessageAt', isNull: false)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        int unread = 0;
        for (final doc in snap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['lastMessageBy'] != myRole) unread++;
        }

        if (unread == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
          child: Text(
            unread > 9 ? '9+' : '$unread',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        );
      },
    );
  }
}