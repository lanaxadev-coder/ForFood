// ============================================================
// VERIFY EMAIL VIEW — SHARED FOR USER + RESTAURANT
// Matches existing design: Yellow top + White bottom section
// ============================================================

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart'; // ✅ ADDED
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/resend_code_button.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/service/signup/signup_bloc.dart';
import 'package:forfood/service/signup/signup_event.dart';
import 'package:forfood/service/signup/signup_state.dart';

class VerifyEmailView extends StatefulWidget {
  final String email;
  final String password;
  final String fullName;
  final UserRole role;
  final String? address;
  final double? latitude;
  final double? longitude;

  const VerifyEmailView({
    super.key,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    this.address,
    this.latitude,
    this.longitude,
  });

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  bool _isChecking = false;
    Completer<void>? _resendCompleter;   // 👈 ADD

  void _handleCheckVerification() {
    setState(() => _isChecking = true );
    context.read<SignupBloc>().add(const SignupEventCheckVerification());
  }

Future<void> _handleResendEmail() async {
  _resendCompleter = Completer<void>();

  context.read<SignupBloc>().add(
        SignupEventResendEmail(
          email: widget.email,
          password: widget.password,
        ),
      );

  // Wait until the bloc finishes (success or error)
  await _resendCompleter!.future;
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    return BlocListener<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state is SignupStateEmailVerified) {
          setState(() => _isChecking = false);

          // ✅ Fetch fullName from Firebase if not provided (e.g., from login redirect)
          String finalName = widget.fullName;
          if (finalName.isEmpty) {
            final currentUser = FirebaseAuth.instance.currentUser;
            finalName = currentUser?.displayName ?? 'User';
          }

          context.read<SignupBloc>().add(
                SignupEventSubmit(
                  email: widget.email,
                  password: widget.password,
                  confirmPassword: widget.password,
                  fullName: finalName,
                  role: widget.role,
                  address: widget.address,
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                ),
              );
        }

 if (state is SignupStateNotVerifiedYet) {
    print('🔔 LISTENER FIRED: NotVerifiedYet');

  setState(() => _isChecking = false);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        '⚠️ Please verify your email first. Open the link we sent to your inbox.',
      ),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 3),
    ),
  );
}
if (state is SignupStateWaitingForVerification) {
  // 👈 Unblock the button first
  _resendCompleter?.complete();
  _resendCompleter = null;

  // ✅ Then show the green snackbar — now correctly sequenced
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('✅ Verification email sent again!'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ),
  );
}

      if (state is SignupStateError) {
  _resendCompleter?.complete();       // 👈 unblock (don't throw)
  _resendCompleter = null;

  setState(() => _isChecking = false);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(state.generalError ?? 'Something went wrong'),
      backgroundColor: Colors.red,
    ),
  );
}
      },
      child: Scaffold(
        body: Container(
          width: screenWidth,
          height: screenHeight,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: AppColor.yellow,
            shape: RoundedRectangleBorder(
            ),
          ),
          child: Stack(
            children: [
              // White bottom section
              Positioned(
                left: 0,
                top: 163 * heightScale,
                child: Container(
                  width: screenWidth,
                  height: screenHeight - (163 * heightScale),
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

              // Back arrow
              Positioned(
                left: 35 * widthScale,
                top: 84 * heightScale,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    'assets/icons/BackiconArrow.png',
                    width: 20 * widthScale,
                    height: 20 * heightScale,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Title
              Positioned(
                left: 0,
                right: 0,
                top: 76 * heightScale,
                child: Text(
                  'Verify Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColor.nearWhite,
                    fontSize: 26 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Content in white section
              Positioned(
                left: 0,
                right: 0,
                top: 163 * heightScale,
                bottom: 0,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 40 * heightScale),

                      // Email icon
                      SvgPicture.asset(
                        'assets/icons/Gmail.svg',
                        width: 80 * widthScale,
                        height: 80 * heightScale,
                        fit: BoxFit.contain,
                      ),

                      SizedBox(height: 25 * heightScale),

                      // Main message
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40 * widthScale),
                        child: Text(
                          "We've sent a verification link to:",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColor.textDark,
                            fontSize: 16 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      SizedBox(height: 10 * heightScale),

                      // Email shown prominently
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColor.orange,
                          fontSize: 18 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      SizedBox(height: 20 * heightScale),

                      // Instructions
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40 * widthScale),
                        child: Text(
                          'Open your email and click the verification link to activate your account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColor.textDark,
                            fontSize: 14 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w300,
                            height: 1.5,
                          ),
                        ),
                      ),

                      SizedBox(height: 30 * heightScale),

                      // Resend button with timer
                      ResendCodeButton(
                        onResend: _handleResendEmail,
                      ),

                      SizedBox(height: 40 * heightScale),

                      // "I've Verified" button
                      GestureDetector(
                        onTap: _isChecking ? null : _handleCheckVerification,
                        child: Container(
                          width: 230 * widthScale,
                          height: 50 * heightScale,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _isChecking ? AppColor.gray : AppColor.orange,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: _isChecking
                              ? SizedBox(
                                  width: 24 * widthScale,
                                  height: 24 * heightScale,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "I've Verified ✓",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 40 * heightScale),

                      // Spam hint
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40 * widthScale),
                        child: Text(
                          "Didn't receive the email? Check your spam folder or use the resend button above.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColor.gray,
                            fontSize: 12 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),

                      SizedBox(height: 30 * heightScale),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}