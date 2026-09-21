// ============================================================
// SKELETON LOADERS
// ============================================================
// Animated placeholder widgets that mimic loading state.
// Used instead of CircularProgressIndicator for better UX.
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:shimmer/shimmer.dart';

/// Base skeleton loader with pulsing animation.
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final color = Color.lerp(
          const Color(0xFFE0E0E0),
          const Color(0xFFF0F0F0),
          _controller.value,
        );

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

// ============================================================
// RESTAURANT CARD SKELETON
// ============================================================
// Mimics the RestaurantCard layout.
// ============================================================
class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return Container(
      width: 323 * widthScale,        // 👈 responsive (was hardcoded 323)
      height: 128 * widthScale,       // 👈 responsive
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 170 * widthScale,  // 👈
            height: 127 * widthScale,
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoader(width: 80, height: 16),
                SizedBox(height: 20),
                SkeletonLoader(width: 100, height: 28),
              ],
            ),
          ),
          Container(
            width: 170 * widthScale,  // 👈
            height: 127 * widthScale,
            decoration: BoxDecoration(
              color: const Color(0xFFD0D0D0),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// HIGH DEMAND CARD SKELETON
// ============================================================
class HighDemandCardSkeleton extends StatelessWidget {
  const HighDemandCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
     final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;
    return Container(
      width: 159 * widthScale,        // 👈 FIXED width (was double.infinity)
      height: 140 * widthScale,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Padding(
            padding: EdgeInsets.all(12),
            child: SkeletonLoader(width: 120, height: 16),
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.all(12),
            child: SkeletonLoader(width: 80, height: 20),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// ORDER CARD SKELETON
// ============================================================

class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 353,
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 19),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SkeletonLoader(width: 120, height: 18),
          SizedBox(height: 8),
          SkeletonLoader(width: 200, height: 12),
        ],
      ),
    );
  }
}

// ============================================================
// MENU ITEM SKELETON (horizontal card)
// ============================================================

class MenuItemCardSkeleton extends StatelessWidget {
  const MenuItemCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 122,
      height: 148,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(38),
      ),
      child: Column(
        children: const [
          Padding(
            padding: EdgeInsets.all(11),
            child: SkeletonLoader(width: 97, height: 75, borderRadius: 17),
          ),
          SizedBox(height: 4),
          SkeletonLoader(width: 60, height: 14),
          SizedBox(height: 4),
          SkeletonLoader(width: 40, height: 20),
        ],
      ),
    );
  }
}

// ============================================================
// NOTIFICATION TILE SKELETON
// ============================================================

class NotificationTileSkeleton extends StatelessWidget {
  const NotificationTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SkeletonLoader(width: 8, height: 8, shape: BoxShape.circle),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 80, height: 16),
                SizedBox(height: 6),
                SkeletonLoader(width: 180, height: 12),
                SizedBox(height: 4),
                SkeletonLoader(width: 60, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// GALLERY CARD SKELETON — matches home + gallery layouts
// ============================================================

class GalleryCardSkeleton extends StatelessWidget {
  final double? width;
  final double? height;

  const GalleryCardSkeleton({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        width: width ?? 118 * widthScale,
        height: height ?? 230 * widthScale,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}
// Add to skeleton_loader.dart
class MenuListItemSkeleton extends StatelessWidget {
  const MenuListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 355,
      height: 102,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColor.orange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(38),
      ),
      child: Row(
        children: [
          // Image skeleton
          Container(
            width: 105,
            height: 81,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          const SizedBox(width: 16),
          // Text skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 16,
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// RESULT CARD SKELETON
// ============================================================

class ResultCardSkeleton extends StatelessWidget {
  const ResultCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.orange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 12,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 60,
                  height: 14,
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RESTAURANT DETAIL SKELETON
// ============================================================

class RestaurantDetailSkeleton extends StatelessWidget {
  const RestaurantDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 163,
                height: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0E0E0),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 150,
                height: 20,
                color: const Color(0xFFE0E0E0),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 20,
              color: const Color(0xFFE0E0E0),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 14,
              color: const Color(0xFFE0E0E0),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              height: 14,
              color: const Color(0xFFE0E0E0),
            ),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 20,
              color: const Color(0xFFE0E0E0),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) => Container(
                  width: 116,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(20),
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