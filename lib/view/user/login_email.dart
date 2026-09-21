// ============================================================
// LOGIN WITH EMAIL — USER SIDE (RESPONSIVE — WITH FIELD ERRORS)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/snack_bar.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_event.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/service/login/login_bloc.dart';
import 'package:forfood/service/login/login_event.dart';
import 'package:forfood/service/login/login_state.dart';
import 'package:forfood/utilities/page_transition.dart';

import 'package:forfood/view/forget_password_email.dart';
import 'package:forfood/view/user/signup_email_verification.dart';
import 'package:forfood/view/verify_email_view.dart';

class LoginWithEmailUserView extends StatefulWidget {
  final UserRole role;

  const LoginWithEmailUserView({super.key, required this.role});

  @override
  State<LoginWithEmailUserView> createState() => _LoginWithEmailUserViewState();
}

class _LoginWithEmailUserViewState extends State<LoginWithEmailUserView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, loginState) {
        if (loginState is LoginStateError && loginState.generalError != null) {
          AppSnackbar.showError(context, loginState.generalError!);
        }

        // ✅ Corrected: use instance field, not static
        if (loginState is LoginStateError && loginState.isEmailNotVerified) {
          Navigator.push(
            context,
            fadeSlideRoute(
              VerifyEmailView(
                email: _emailController.text.trim(),
                password: _passwordController.text,
                fullName: '', // Will be fetched later or placeholder
                role: widget.role,
              ),
            ),
          );
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          final isLoading = state is LoginStateLoading;
          final isPasswordVisible = state is LoginStatePasswordVisibility
              ? state.isPasswordVisible
              : false;
          final emailError =
              state is LoginStateError ? state.emailError : null;
          final passwordError =
              state is LoginStateError ? state.passwordError : null;

          // ✅ Keyboard dismiss wrapper
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              body: Container(
                width: double.infinity,
                height: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: AppColor.yellow,
                  shape: RoundedRectangleBorder(
                  ),
                ),
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: screenHeight,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
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
                        Positioned(
                          left: 162 * widthScale,
                          top: 76 * heightScale,
                          child: Text(
                            'Hello!',
                            style: TextStyle(
                              color: AppColor.nearWhite,
                              fontSize: 28 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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
                        Positioned(
                          left: 34 * widthScale,
                          top: 195 * heightScale,
                          child: Text(
                            'Welcome',
                            style: TextStyle(
                              color: AppColor.textDark,
                              fontSize: 24 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 36 * widthScale,
                          top: 255 * heightScale,
                          child: Text(
                            'Email',
                            style: TextStyle(
                              color: AppColor.textDark,
                              fontSize: 20 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 36 * widthScale,
                          top: 285 * heightScale,
                          child: Container(
                            width: 322 * widthScale,
                            height: 45 * heightScale,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              color: AppColor.yellow2,
                            ),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'example@example.com',
                                hintStyle: TextStyle(
                                  color: AppColor.gray,
                                  fontFamily: 'League Spartan',
                                  fontSize: 18 * widthScale,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16 * widthScale,
                                  vertical: 12 * heightScale,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (emailError != null)
                          Positioned(
                            left: 36 * widthScale,
                            top: 332 * heightScale,
                            child: Text(
                              emailError,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        Positioned(
                          left: 36 * widthScale,
                          top: 355 * heightScale,
                          child: Text(
                            'Password',
                            style: TextStyle(
                              color: AppColor.textDark,
                              fontSize: 20 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 36 * widthScale,
                          top: 384 * heightScale,
                          child: Container(
                            width: 322 * widthScale,
                            height: 45 * heightScale,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              color: AppColor.yellow2,
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: !isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: '*************',
                                hintStyle: TextStyle(
                                  color: AppColor.gray,
                                  fontFamily: 'League Spartan',
                                  fontSize: 18 * widthScale,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16 * widthScale,
                                  vertical: 12 * heightScale,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (passwordError != null)
                          Positioned(
                            left: 36 * widthScale,
                            top: 431 * heightScale,
                            child: Text(
                              passwordError,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        Positioned(
                          left: 325 * widthScale,
                          top: 400 * heightScale,
                          child: InkWell(
                            onTap: () {
                              context.read<LoginBloc>().add(
                                    const LoginEventTogglePasswordVisibility(),
                                  );
                            },
                            child: SvgPicture.asset(
                              'assets/icons/ShowOff.svg',
                              width: 15 * widthScale,
                              height: 15 * heightScale,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 255 * widthScale,
                          top: 440 * heightScale,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                fadeSlideRoute(
                                  ForgetPasswordEmailView(
                                    role: widget.role,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'forget password',
                              style: TextStyle(
                                color: AppColor.orange,
                                fontFamily: 'League Spartan',
                                fontSize: 12 * widthScale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 96 * widthScale,
                          top: 520 * heightScale,
                          child: InkWell(
                            onTap: isLoading
                                ? null
                                : () {
                                    context.read<LoginBloc>().add(
                                          LoginEventSubmit(
                                            email: _emailController.text,
                                            password:
                                                _passwordController.text,
                                          ),
                                        );
                                  },
                            child: Container(
                              width: 207 * widthScale,
                              height: 45 * heightScale,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: isLoading
                                    ? AppColor.gray
                                    : AppColor.orange,
                              ),
                              child: Center(
                                child: isLoading
                                    ? SizedBox(
                                        width: 24 * widthScale,
                                        height: 24 * heightScale,
                                        child:
                                            const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Log In',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'League Spartan',
                                          fontSize: 22 * widthScale,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 580 * heightScale,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  color: AppColor.textDark,
                                  fontFamily: 'League Spartan',
                                  fontSize: 12 * widthScale,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    fadeSlideRoute(
                                      SignupWithEmailUser(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: AppColor.orange,
                                    fontFamily: 'League Spartan',
                                    fontSize: 12 * widthScale,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 630 * heightScale,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'or Sign in with',
                                style: TextStyle(
                                  color: AppColor.textDark,
                                  fontFamily: 'League Spartan',
                                  fontSize: 12 * widthScale,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () {
                                  context.read<AuthBloc>().add(
                                        const AuthEventGoogleSignIn(),
                                      );
                                },
                                child: SvgPicture.asset(
                                  'assets/icons/GoogleIcon.svg',
                                  width: 30 * widthScale,
                                  height: 30 * heightScale,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}