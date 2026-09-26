// ============================================================
// DELETE ACCOUNT DIALOG — wired to AuthBloc
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_event.dart';
import 'package:forfood/utilities/friendly_error.dart';

void showDeleteUserDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColor.nearWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => Padding(
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
              // ── CANCEL ──
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(sheetContext),
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

              // ── CONFIRM DELETE ──
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    // Capture BEFORE any await / pop
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(sheetContext);
                    final authBloc = context.read<AuthBloc>();

                    // 1. Ask for password
                    final password = await _askPassword(sheetContext);
                    if (password == null || password.isEmpty) return;

                    // 2. Close bottom sheet
                    navigator.pop();

                    // 3. Re-auth, then dispatch delete
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null || user.email == null) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('No logged-in user found.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: password,
                      );
                      await user.reauthenticateWithCredential(credential);

                      authBloc.add(const AuthEventDeleteAccount());
                    } on FirebaseAuthException catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                              content: Text(friendlyError(e)),

                          backgroundColor: Colors.red,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
      content: Text(friendlyError(e)),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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

Future<String?> _askPassword(BuildContext context) async {
  final controller = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.nearWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Confirm your password',
          style: TextStyle(
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColor.orange),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: AppColor.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}