// ============================================================
// SIGNUP WITH EMAIL — RESTAURANT SIDE — CLEAN FLOW
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:forfood/core/widgets/location_map_picker.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/snack_bar.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_event.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/service/signup/signup_bloc.dart';
import 'package:forfood/service/signup/signup_event.dart';
import 'package:forfood/service/signup/signup_state.dart';

import 'package:forfood/view/verify_email_view.dart';
import 'package:forfood/view/restaurant/login_email.dart';

class SignupWithEmailRestaurant extends StatefulWidget {
  const SignupWithEmailRestaurant({super.key});

  @override
  State<SignupWithEmailRestaurant> createState() =>
      _SignupWithEmailRestaurantState();
}

class _SignupWithEmailRestaurantState
    extends State<SignupWithEmailRestaurant> {
  late final TextEditingController _emailAdressController;
  late final TextEditingController _adressONGoogleMapController;
  late final TextEditingController _restaurantNameController;
  late final TextEditingController _emailPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  double? _restaurantLatitude;
  double? _restaurantLongitude;

  @override
  void initState() {
    super.initState();
    _restaurantNameController = TextEditingController();
    _emailAdressController = TextEditingController();
    _adressONGoogleMapController = TextEditingController();
    _emailPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailAdressController.dispose();
    _adressONGoogleMapController.dispose();
    _emailPasswordController.dispose();
    _confirmPasswordController.dispose();
    _restaurantNameController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }
   



   Future<void> _openLocationPicker() async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => LocationMapPicker(
        initialLatitude: _restaurantLatitude ?? 36.7538,
        initialLongitude: _restaurantLongitude ?? 3.0588,
        initialAddress: _adressONGoogleMapController.text,
        onConfirmed: (address, lat, lng) {
          setState(() {
            _adressONGoogleMapController.text = address;
            _restaurantLatitude = lat;
            _restaurantLongitude = lng;
          });
        },
      ),
    ),
  );
}
  // ✅ Clean submit → create temp user + send email → navigate to verify
  void _handleSignUp() {
    final email = _emailAdressController.text.trim();
    final restaurantName = _restaurantNameController.text.trim();
    final password = _emailPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final address = _adressONGoogleMapController.text.trim();

    if (restaurantName.isEmpty) {
      AppSnackbar.showError(context, 'Restaurant name is required');
      return;
    }
    if (email.isEmpty) {
      AppSnackbar.showError(context, 'Email is required');
      return;
    }
    if (address.isEmpty) {
      AppSnackbar.showError(context, 'Restaurant address is required');
      return;
    }
    if (password.length < 6) {
      AppSnackbar.showError(context, 'Password must be at least 6 characters');
      return;
    }
    if (password != confirmPassword) {
      AppSnackbar.showError(context, 'Passwords do not match');
      return;
    }

    context.read<SignupBloc>().add(
          SignupEventVerifyEmail(
            email: email,
            password: password,
                fullName: restaurantName, // ✅ ADD

          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    return BlocListener<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state is SignupStateError && state.generalError != null) {
          AppSnackbar.showError(context, state.generalError!);
        }

        // ✅ Navigate to VerifyEmailView
        if (state is SignupStateWaitingForVerification) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyEmailView(
                email: _emailAdressController.text.trim(),
                password: _emailPasswordController.text,
                fullName: _restaurantNameController.text.trim(),
                role: UserRole.restaurant,
                address: _adressONGoogleMapController.text.trim(),
                latitude: _restaurantLatitude,
                longitude: _restaurantLongitude,
              ),
            ),
          );
        }if (state is SignupStateEmailAlreadyRegistered) {
  AppSnackbar.showError(
    context,
    'This email is already registered. Please log in.',
  );
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => LoginWithEmailRestaurantView(role: UserRole.restaurant
      ),
    ),
  );
}
      },
      child: BlocBuilder<SignupBloc, SignupState>(
        builder: (context, state) {
          final isLoading = state is SignupStateLoading;

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              body: Container(
                width: double.infinity,
                height: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: const Color(0xFFF5CB58),
                  shape: RoundedRectangleBorder(
                  ),
                ),
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: screenHeight,
                    child: Stack(
                      children: [
                        // White bottom section
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 163 * heightScale,
                          child: Container(
                            width: screenWidth,
                            height: screenHeight - (163 * heightScale),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                          ),
                        ),

                        // Title
                        Positioned(
                          left: 116 * widthScale,
                          top: 76 * heightScale,
                          child: Text(
                            'New Account',
                            style: TextStyle(
                              color: AppColor.nearWhite,
                              fontSize: 28 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Back button
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

                        // Email label
                        Positioned(
                          left: 30 * widthScale,
                          top: 180 * heightScale,
                          child: Text(
                            'Email',
                            style: TextStyle(
                              color: const Color(0xFF391713),
                              fontSize: 18 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Email field
                        Positioned(
                          left: 22 * widthScale,
                          top: 209 * heightScale,
                          child: Container(
                            width: 322 * widthScale,
                            height: 45 * heightScale,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              color: AppColor.yellow2,
                            ),
                            child: TextField(
                              controller: _emailAdressController,
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

                        // Restaurant name label
                        Positioned(
                          left: 30 * widthScale,
                          top: 272 * heightScale,
                          child: Text(
                            "Restaurant's Name",
                            style: TextStyle(
                              color: const Color(0xFF391713),
                              fontSize: 18 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Restaurant name field
                        Positioned(
                          left: 22 * widthScale,
                          top: 302 * heightScale,
                          child: Container(
                            width: 322 * widthScale,
                            height: 45 * heightScale,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              color: AppColor.yellow2,
                            ),
                            child: TextField(
                              controller: _restaurantNameController,
                              decoration: InputDecoration(
                                hintText: 'Pizza Rapide',
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

                        // Address label
                        Positioned(
                          left: 30 * widthScale,
                          top: 365 * heightScale,
                          child: Text(
                            'Address On Google Map',
                            style: TextStyle(
                              color: const Color(0xFF252525),
                              fontSize: 18 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Address field with location picker
                       // Address field — tap to open picker
Positioned(
  left: 21 * widthScale,
  top: 391 * heightScale,
  child: GestureDetector(
    onTap: _openLocationPicker,
    child: Container(
      width: 322 * widthScale,
      height: 45 * heightScale,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: AppColor.yellow2,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16 * widthScale),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _adressONGoogleMapController.text.isEmpty
                  ? 'Tap to pick on map'
                  : _adressONGoogleMapController.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _adressONGoogleMapController.text.isEmpty
                    ? AppColor.gray
                    : AppColor.textDark,
                fontFamily: 'League Spartan',
                fontSize: 16 * widthScale,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const Icon(
            Icons.location_on,
            color: AppColor.orange,
            size: 20,
          ),
        ],
      ),
    ),
  ),
),
                        // Password label
                        Positioned(
                          left: 29 * widthScale,
                          top: 454 * heightScale,
                          child: Text(
                            'Password',
                            style: TextStyle(
                              color: const Color(0xFF252525),
                              fontSize: 18 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Password field
                        Positioned(
                          left: 20 * widthScale,
                          top: 479 * heightScale,
                          child: Container(
                            width: 322 * widthScale,
                            height: 45 * heightScale,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              color: AppColor.yellow2,
                            ),
                            child: TextField(
                              controller: _emailPasswordController,
                              obscureText: !_isPasswordVisible,
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

                        // Password visibility
                        Positioned(
                          left: 310 * widthScale,
                          top: 491 * heightScale,
                          child: InkWell(
                            onTap: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                            child: SvgPicture.asset(
                              'assets/icons/ShowOff.svg',
                              width: 15 * widthScale,
                              height: 15 * widthScale,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // Confirm Password label
                        Positioned(
                          left: 21 * widthScale,
                          top: 542 * heightScale,
                          child: Text(
                            'Confirm Password',
                            style: TextStyle(
                              color: const Color(0xFF252525),
                              fontSize: 18 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Confirm Password field
                        Positioned(
                          left: 20 * widthScale,
                          top: 571 * heightScale,
                          child: Container(
                            width: 322 * widthScale,
                            height: 45 * heightScale,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              color: AppColor.yellow2,
                            ),
                            child: TextField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
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

                        // Confirm Password visibility
                        Positioned(
                          left: 305 * widthScale,
                          top: 583 * heightScale,
                          child: InkWell(
                            onTap: () => setState(() => _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible),
                            child: SvgPicture.asset(
                              'assets/icons/ShowOff.svg',
                              width: 15 * widthScale,
                              height: 15 * widthScale,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // Terms
                        Positioned(
                          top: 630 * heightScale,
                          left: 10 * widthScale,
                          right: 10 * widthScale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'By continuing, you agree to',
                                style: TextStyle(
                                  color: const Color(0xFF391713),
                                  fontSize: 11 * widthScale,
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        _launchUrl('https://www.forfood.com/privacy-policy'),
                                    child: Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        color: AppColor.orange,
                                        fontSize: 11 * widthScale,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' and ',
                                    style: TextStyle(
                                      color: const Color(0xFF391713),
                                      fontSize: 11 * widthScale,
                                      fontFamily: 'League Spartan',
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        _launchUrl('https://www.forfood.com/terms-of-service'),
                                    child: Text(
                                      'Terms of Use',
                                      style: TextStyle(
                                        color: const Color(0xFFE95322),
                                        fontSize: 11 * widthScale,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ✅ Single Sign Up button
                        Positioned(
                          left: 97 * widthScale,
                          top: 680 * heightScale,
                          child: InkWell(
                            onTap: isLoading ? null : _handleSignUp,
                            child: Container(
                              width: 207 * widthScale,
                              height: 45 * heightScale,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: isLoading ? AppColor.gray : AppColor.orange,
                              ),
                              child: Center(
                                child: isLoading
                                    ? SizedBox(
                                        width: 24 * widthScale,
                                        height: 24 * heightScale,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20 * widthScale,
                                          fontFamily: 'League Spartan',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        // Google Sign In
                        Positioned(
                          top: 740 * heightScale,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Text(
                                'or sign in with',
                                style: TextStyle(
                                  color: const Color(0xFF391713),
                                  fontSize: 12 * widthScale,
                                  fontFamily: 'League Spartan',
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

                        // Already have account
                        Positioned(
                          top: 790 * heightScale,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: AppColor.black,
                                  fontFamily: 'League Spartan',
                                  fontSize: 12 * widthScale,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LoginWithEmailRestaurantView(
                                        role: UserRole.restaurant,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Log in',
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