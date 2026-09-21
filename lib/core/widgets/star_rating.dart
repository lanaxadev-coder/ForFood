import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StarRating extends StatelessWidget {
  final int rating;       // how many stars are filled, 0-5
  final int totalStars;

  const StarRating({
    super.key,
    required this.rating,
    this.totalStars = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalStars, (index) {
        return SvgPicture.asset(
          index < rating 
              ? 'assets/icons/bot-star-1.svg'  // ✅ Full star
              : 'assets/icons/bot-star-3.svg', // ✅ Empty star
          width: 25,
          height: 25,
          fit: BoxFit.contain,
        );
        
      },
      ),
    );
  }
}