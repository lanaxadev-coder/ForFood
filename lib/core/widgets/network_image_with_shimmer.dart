// ============================================================
// NETWORK IMAGE WITH SHIMMER + DISK CACHE
// ============================================================
// Uses cached_network_image so images survive app restarts and
// screen navigations. Shimmer placeholder shown on first load.
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
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
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        // Shown while downloading the first time.
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: width,
            height: height,
            color: Colors.grey[300],
          ),
        ),
        // Shown if the download fails.
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: const Color(0xFFFFDECF),
          child: const Icon(
            Icons.image,
            color: Color(0xFFE95322),
            size: 30,
          ),
        ),
      ),
    );
  }
}