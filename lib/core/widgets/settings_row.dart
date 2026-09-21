import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forfood/core/theme/app_color.dart';

class SettingsRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColor.textDark,
                      fontSize: 20,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/NexticonArrow.svg',
                  width: 15,
                  height: 15,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
        // ✅ Divider after every row
        Container(
          height: 1,
          color: AppColor.divider,
        ),
      ],
    );
  }
}