import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';

void showErrortDialog(BuildContext context , String message) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColor.nearWhite,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           Text( message , textAlign: TextAlign.center, style: TextStyle(
            color: Colors.black, fontSize: 20, fontFamily: 'League Spartan', fontWeight: FontWeight.w500,
          )),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFFFFDECF), borderRadius: BorderRadius.circular(50)),
                    child: const Text('Try again ', style: TextStyle(color: AppColor.orange, fontSize: 17, fontFamily: 'League Spartan',fontWeight : FontWeight.w600)),
                  ),
                ),
              ),
             
            ],
          ),
        ],
      ),
    ),
  );
}