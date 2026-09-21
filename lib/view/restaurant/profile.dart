// ============================================================
// RESTAURANT PROFILE VIEW — FIXED LATE INIT + BOTTOM NAV
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forfood/service/auth/auth_event.dart';
import 'package:forfood/service/auth/auth_user.dart';
import 'package:forfood/utilities/geohach_util.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';
import 'package:image_picker/image_picker.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/profile_avatar.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';

import 'package:forfood/view/restaurant/home_page.dart';
import 'package:forfood/view/restaurant/incoming_order.dart';
import 'package:forfood/view/restaurant/menu.dart';

class ProfileViewRestaurant extends StatefulWidget {
  const ProfileViewRestaurant({super.key});

  @override
  State<ProfileViewRestaurant> createState() => _ProfileViewRestaurantState();
}

class _ProfileViewRestaurantState extends State<ProfileViewRestaurant> {
  int _currentIndex = 4; // ✅ Set to Profile tab
  bool _isSaving = false;
  File? _selectedImage;
  final FirestoreProvider _firestoreProvider = FirestoreProvider();
  final ImagePicker _imagePicker = ImagePicker();

  // ✅ FIXED: Initialize with empty strings instead of late
  final TextEditingController _restaurantName = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _restaurantAdress = TextEditingController();
  final TextEditingController _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      _emailController.text = authState.user.email;
      try {
        final restaurant =
            await _firestoreProvider.getRestaurantByOwnerId(authState.user.id);
        if (restaurant != null && mounted) {
          setState(() {
            _restaurantName.text = restaurant.name;
            _restaurantAdress.text = restaurant.address;
            _description.text = restaurant.description;
            _phoneController.text = restaurant.phoneNumber ?? '';
          });
        } else {
          setState(() {
            _restaurantName.text = authState.user.fullName;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _restaurantName.text = authState.user.fullName;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _restaurantName.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _restaurantAdress.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }Future<void> _handleUpdateProfile() async {
  final name = _restaurantName.text.trim();
  final address = _restaurantAdress.text.trim();
  final description = _description.text.trim();
  final phone = _phoneController.text.trim();

  if (name.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restaurant name is required')),
    );
    return;
  }

  if (address.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address is required')),
    );
    return;
  }

  final authState = context.read<AuthBloc>().state;
  if (authState is! AuthStateLoggedIn) return;

  setState(() => _isSaving = true);

  try {
    // 1. Fetch restaurant
    final restaurant =
        await _firestoreProvider.getRestaurantByOwnerId(authState.user.id);

    if (restaurant == null) {
      throw const RestaurantNotFoundException('unknown');
    }

    // 1b. Fetch the existing user doc so we can preserve createdAt
    final existingUser =
        await _firestoreProvider.getUserById(authState.user.id);

    // 2. Upload new image if picked
    String? imageUrl = restaurant.profileImageUrl;
    if (_selectedImage != null) {
      imageUrl = await _firestoreProvider.uploadImage(
        file: _selectedImage!,
        path:
            'restaurants/${restaurant.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }

    // 3. Update restaurant doc
    final updatedRestaurant = restaurant.copyWith(
      name: name,
      address: address,
      description: description,
      phoneNumber: phone.isEmpty ? null : phone,
      profileImageUrl: imageUrl,
       geohash: GeohashUtil.encode(
    latitude: restaurant.latitude,
    longitude: restaurant.longitude,
  ), 
    );
    await _firestoreProvider.updateRestaurant(updatedRestaurant);

    // 4. Update user doc — preserve original createdAt
    final updatedUser = existingUser.copyWith(
      fullName: name,
      phoneNumber: phone.isEmpty ? null : phone,
      profileImageUrl: imageUrl,
    );
    await _firestoreProvider.updateUser(updatedUser);

    if (!mounted) return;

    // 4b. Push the fresh user into AuthBloc so every screen picks it up
    context.read<AuthBloc>().add(
          AuthEventLoggedIn(
            user: AuthUser(
              id: updatedUser.id,
              fullName: updatedUser.fullName,
              email: updatedUser.email,
              phoneNumber: updatedUser.phoneNumber,
              profileImageUrl: updatedUser.profileImageUrl,
              role: updatedUser.role,
            ),
          ),
        );

    // 5. Show success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // 6. Drop the temp file — AuthBloc now holds the real remote URL
    setState(() {
      _selectedImage = null;
    });
  } on RestaurantNotFoundException {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant not found')),
      );
    }
  } on FirestoreOperationException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
  // ✅ FIXED: Bottom nav navigation
 void _handleBottomNavTap(int index) {
  if (index == _currentIndex) return;

  switch (index) {
    case 0:
      Navigator.of(context).pushAndRemoveUntil(
        tabRoute(const RestaurantHomeView()),
        (route) => false,
      );
      break;
    case 1:
      Navigator.of(context).pushAndRemoveUntil(
        tabRoute(const OrdersView()),
        (route) => false,
      );
      break;
    case 2:
      Navigator.of(context).push(tabRoute(const ChatInboxView()));
      break;
    case 3:
      Navigator.of(context).push(tabRoute(const MenuListView()));
      break;
    case 4:
      Navigator.of(context).push(
        tabRoute(const ProfileViewRestaurant()),
      );
      break;
  }
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String restaurantName = '';
        String restaurantEmail = '';
        String? profileImageUrl;

        if (authState is AuthStateLoggedIn) {
          restaurantName = authState.user.fullName;
          restaurantEmail = authState.user.email;
          profileImageUrl = authState.user.profileImageUrl;
        }

        return GestureDetector(
  onTap: () => FocusScope.of(context).unfocus(),
  child:  Scaffold(
          endDrawer: buildRestaurantDrawer(
            name: restaurantName,
            email: restaurantEmail,
            profileImageUrl: profileImageUrl,
          ),
          body: Container(
            width: screenWidth,
            height: screenHeight,
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: const Color(0xFFF5CB58),
              shape: RoundedRectangleBorder(
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 163 * heightScale,
                  child: Container(
                    width: screenWidth,
                    height: screenHeight - (163 * heightScale),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF5F5F5),
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
                  left: 116 * widthScale,
                  top: 76 * heightScale,
                  child: Text(
                    'My Profile',
                    style: TextStyle(
                      color: AppColor.nearWhite,
                      fontSize: 28 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  top: 163 * heightScale,
                  bottom: 0,
                  child: ListView(
                    padding: EdgeInsets.only(top: 20 * heightScale),
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: ProfileAvatar(
                                imageUrl: _selectedImage != null
                                    ? _selectedImage!.path
                                    : profileImageUrl,
                                size: 127 * widthScale,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 26 * widthScale,
                                  height: 26 * heightScale,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColor.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    color: AppColor.white,
                                    size: 14 * widthScale,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30 * heightScale),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 35 * widthScale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Restaurant Name',
                              style: TextStyle(
                                color: AppColor.textDark,
                                fontSize: 20 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8 * heightScale),
                            Container(
                              height: 45 * heightScale,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E9B5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextField(
                                controller: _restaurantName,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                ),
                              ),
                            ),

                            SizedBox(height: 20 * heightScale),
                            Text(
                              'Email',
                              style: TextStyle(
                                color: AppColor.textDark,
                                fontSize: 20 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8 * heightScale),
                            Container(
                              height: 45 * heightScale,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E9B5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),

                            SizedBox(height: 20 * heightScale),
                            Text(
                              "Restaurant's Address",
                              style: TextStyle(
                                color: AppColor.textDark,
                                fontSize: 20 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8 * heightScale),
                            Container(
                              height: 45 * heightScale,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E9B5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextField(
                                controller: _restaurantAdress,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                  hintText: '321 East 14th Street, Manhattan, NY',
                                  hintStyle: TextStyle(
                                    color: AppColor.gray,
                                    fontSize: 15 * widthScale,
                                    fontFamily: 'League Spartan',
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),

                            SizedBox(height: 20 * heightScale),
                            Text(
                              'Phone Number (optional)',
                              style: TextStyle(
                                color: AppColor.textDark,
                                fontSize: 20 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8 * heightScale),
                            Container(
                              height: 45 * heightScale,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E9B5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                  hintText: '01 23 45 67 89',
                                  hintStyle: TextStyle(
                                    color: AppColor.gray,
                                    fontSize: 15 * widthScale,
                                    fontFamily: 'League Spartan',
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),

                            SizedBox(height: 20 * heightScale),
                            Text(
                              'Description',
                              style: TextStyle(
                                color: AppColor.textDark,
                                fontSize: 20 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8 * heightScale),
                            Container(
                              height: 95 * heightScale,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E9B5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextField(
                                controller: _description,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                  hintText: 'Describe your restaurant...',
                                  hintStyle: TextStyle(
                                    color: AppColor.gray,
                                    fontSize: 15 * widthScale,
                                    fontFamily: 'League Spartan',
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            SizedBox(height: 40 * heightScale),

                            Center(
                              child: GestureDetector(
                                onTap: _isSaving ? null : _handleUpdateProfile,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24 * widthScale,
                                    vertical: 10 * heightScale,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isSaving ? AppColor.gray : AppColor.orange,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: _isSaving
                                      ? SizedBox(
                                          width: 24 * widthScale,
                                          height: 24 * heightScale,
                                          child: const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Update Profile',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17 * widthScale,
                                            fontFamily: 'League Spartan',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20 * heightScale),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: _handleBottomNavTap,
              isRestaurant: true,  // ✅ ADD THIS

          ),
         ) );
      },
    );
  }
}