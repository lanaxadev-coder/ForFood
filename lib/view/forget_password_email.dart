// ============================================================
// FORGOT PASSWORD VIEW — WIRED TO AUTHBLOC
// ============================================================
// Collects email for password reset.
// Dispatches AuthEventForgotPassword to AuthBloc.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_event.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/auth/user_role.dart';


class ForgetPasswordEmailView extends StatefulWidget {
  final UserRole role;

  const ForgetPasswordEmailView({super.key, required this.role});

  @override
  State<ForgetPasswordEmailView> createState() =>
      _ForgetPasswordEmailViewState();
}

class _ForgetPasswordEmailViewState extends State<ForgetPasswordEmailView> {
  final _emailAddressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailAddressController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND RESET EMAIL
  // ============================================================

  /// Handles "Send" button tap.
  void _handleSendResetEmail() {
    final email = _emailAddressController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is required')),
      );
      return;
    }

    context.read<AuthBloc>().add(
          AuthEventForgotPassword(email: email),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }

        if (state is AuthStateLoggedOut) {
          // Password reset email sent successfully
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent. Check your inbox.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }

        if (state is AuthStateLoading) {
          setState(() => _isLoading = true);
        }
      },
      child: GestureDetector(
  onTap: () => FocusScope.of(context).unfocus(),
  child:  Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: AppColor.yellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Stack(
            children: [
              // White bottom section
              Positioned(
                left: 0,
                top: 163,
                child: Container(
                  width: 393,
                  height: 689,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: AppColor.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),

              // Title
              const Positioned(
                left: 90,
                top: 76,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColor.nearWhite,
                    fontSize: 28,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Back arrow
              Positioned(
                left: 35,
                top: 84,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    'assets/icons/BackiconArrow.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Subtitle
              const Positioned(
                left: 30,
                top: 190,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColor.textDark,
                    fontSize: 20,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Positioned(
                left: 29,
                top: 260,
                child: Text(
                  'Please Enter Your Email Address to Receive a Link',
                  style: TextStyle(
                    color: AppColor.textDark,
                    fontSize: 14,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),

              // Email label
              const Positioned(
                left: 35,
                top: 311,
                child: Text(
                  'Email',
                  style: TextStyle(
                    color: AppColor.textDark,
                    fontSize: 18,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Email field
              Positioned(
                left: 30,
                top: 350,
                child: Container(
                  width: 322,
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: AppColor.yellow2,
                  ),
                  child: TextField(
                    controller: _emailAddressController,
                    decoration: InputDecoration(
                      hintText: 'example@example.com',
                      hintStyle: TextStyle(
                        color: AppColor.gray,
                        fontFamily: 'League Spartan',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              // Send button
              Positioned(
                left: 93,
                top: 450,
                child: InkWell(
                  onTap: _isLoading ? null : _handleSendResetEmail,
                  child: Container(
                    width: 207,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: _isLoading ? AppColor.gray : AppColor.orange,
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Send',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'League Spartan',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),) 
    );
  }
}