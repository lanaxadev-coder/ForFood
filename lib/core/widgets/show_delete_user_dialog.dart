// ============================================================
// DELETE ACCOUNT DIALOG — WIRED TO AUTHBLOC
// ============================================================
// Confirmation dialog for account deletion.
// "Yes, delete" dispatches AuthEventDeleteAccount to AuthBloc.
// Fulfills Apple App Store Guideline 5.1.1(v).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_event.dart';

void showDeleteUserDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColor.nearWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Are you sure you want to delete your account?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This action cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDECF),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColor.orange,
                        fontSize: 17,
                        fontFamily: 'League Spartan',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Close dialog first
                   // Read AuthBloc BEFORE popping
  final authBloc = context.read<AuthBloc>();

  // Close dialog
  Navigator.pop(context);

  // Dispatch event
  authBloc.add(
    const AuthEventDeleteAccount(),
  );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColor.orange,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      'Yes, delete',
                      style: TextStyle(
                        color: AppColor.white,
                        fontSize: 17,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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