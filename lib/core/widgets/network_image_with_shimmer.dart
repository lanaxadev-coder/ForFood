// ============================================================
// NETWORK IMAGE WITH SHIMMER LOADING
// ============================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class NetworkImageWithShimmer extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const NetworkImageWithShimmer({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child; // Image loaded
          }
          // Shimmer while loading
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: width,
              height: height,
              color: Colors.grey[300],
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFFFDECF),
            child: const Icon(
              Icons.image,
              color: Color(0xFFE95322),
              size: 30,
            ),
          );
        },
      ),
    );
  }
}