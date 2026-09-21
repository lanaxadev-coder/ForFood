import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';

class OrderInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const OrderInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(
              color: AppColor.orange, fontSize: 18,
              fontFamily: 'League Spartan', fontWeight: FontWeight.w600,
            )),
          ),
          const SizedBox(width: 30,), 
          Expanded(
            child: Text(value, style: const TextStyle(
              color: AppColor.black, fontSize: 18,
              fontFamily: 'League Spartan', fontWeight: FontWeight.w600,
            )),
          ),
        ],
      ),
    );
  }
}