import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';

class OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasBorder;

  const OtpBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 67,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: AppColor.yellow2,
        border: hasBorder
            ? Border.all(color: AppColor.white, width: 1)
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(fontSize: 24, color: AppColor.brown),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
      ),
    );
  }
}