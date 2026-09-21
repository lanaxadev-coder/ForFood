import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forfood/core/theme/app_color.dart';

class ViewAllLink extends StatelessWidget {
  final VoidCallback onTap;

  const ViewAllLink({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        
        children: [
           Text('View All', style: TextStyle(
            color: AppColor.orange, fontSize: 12,
            fontFamily: 'League Spartan', fontWeight: FontWeight.w700,
          )),
          const SizedBox(width: 4),
          SvgPicture.asset('assets/icons/NexticonArrow.svg', width: 13, height: 13, fit: BoxFit.contain,),
        ],
      ),
    );
  }
}